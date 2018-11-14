require "fileutils"
require "shellwords"

RAILS_REQUIREMENT = ">= 5.2.0.rc1".freeze

def apply_template!
  assert_minimum_rails_version
  assert_postgresql
  add_template_repository_to_source_path

  copy_file "gitignore", ".gitignore", force: true
  template "Gemfile.tt", force: true
  template "ruby-version.tt", ".ruby-version", force: true

  apply "config/template.rb"
  apply "app/template.rb"
  apply "lib/template.rb"

  copy_file "Procfile"
  copy_file "Procfile.dev"

  ask_optional_options

  install_optional_gems

  after_bundle do
    run "spring stop"
    setup_npm_packages

    setup_gems

    run "bundle binstubs bundler --force"

    run "rails db:create db:migrate db:seed"

    git :init unless preexisting_git_repo?
    empty_directory ".git/safe"

    unless any_local_git_commits?
      git add: "-A ."
      git commit: "-n -m 'Set up project'"
      if git_repo_specified?
        git remote: "add origin #{git_repo_url.shellescape}"
        git push: "-u origin --all"
      end
    end
  end
end

def add_template_repository_to_source_path
  if __FILE__ =~ %r{\Ahttps?://}
    require "tmpdir"
    source_paths.unshift(tempdir = Dir.mktmpdir("rails-template-"))
    at_exit { FileUtils.remove_entry(tempdir) }
    git clone: [
      "--quiet",
      "https://github.com/codelation/rails-5-template",
      tempdir
    ].map(&:shellescape).join(" ")
  else
    source_paths.unshift(File.dirname(__FILE__))
  end
end

def gemfile_requirement(name)
  @original_gemfile ||= IO.read("Gemfile")
  req = @original_gemfile[/gem\s+['"]#{name}['"]\s*(,[><~= \t\d\.\w'"]*)?.*$/, 1]
  req && req.tr("'", %(")).strip.sub(/^,\s*"/, ', "')
end

def assert_minimum_rails_version
  requirement = Gem::Requirement.new(RAILS_REQUIREMENT)
  rails_version = Gem::Version.new(Rails::VERSION::STRING)
  return if requirement.satisfied_by?(rails_version)

  prompt = "This template requires Rails #{RAILS_REQUIREMENT}. "\
           "You are using #{rails_version}. Continue anyway?"
  exit 1 if no?(prompt)
end

def assert_postgresql
  return if IO.read("Gemfile") =~ /^\s*gem ['"]pg['"]/

  raise Rails::Generators::Error,
        "This template requires PostgreSQL, "\
        "but the pg gem isn\u2019t present in your Gemfile."
end

def ask_optional_options
  @devise = yes?("Do you want to implement authentication in your app with the Devise gem?")
  @devise_user = yes?("Do you want create a User?") if @devise
  @devise_admin_user = yes?("Do you want create an AdminUser?") if @devise
  @devise_invitable = yes?("Do you want to use invitable with devise?") if @devise
  @active_storage = yes?("Do you want to use ActiveStorage?")
  @pdfs = yes?("Do you want to generate PDFs with this application?")
  @active_admin = yes?("Do you want to use ActiveAdmin for Admin backend?")
end

def install_optional_gems
  add_devise if @devise
  add_pdfs if @pdfs
  add_active_admin if @active_admin
  add_active_storage if @active_storage
end

def add_devise
  insert_into_file "Gemfile", "gem \"devise\"\n", after: /"codelation_assets"\n/
  insert_into_file "Gemfile", "gem \"devise_invitable\"\n", after: /"codelation_assets"\n/ if @devise_invitable
end

def add_pdfs
  insert_into_file "Gemfile", "gem \"wicked_pdf\"\n", after: /"codelation_assets"\n/
  insert_into_file "Gemfile", "gem \"wkhtmltopdf-binary\"\n", after: /"wicked_pdf"\n/
end

def add_active_admin
  insert_into_file "Gemfile", "gem \"activeadmin\"\n", after: /"codelation_assets"\n/
end

def add_active_storage
  insert_into_file "Gemfile", "gem \"aws-sdk-s3\"\n", after: /"codelation_assets"\n/
end

def setup_npm_packages
  add_linters
end

def add_linters
  run "yarn add eslint babel-eslint eslint-config-airbnb-base eslint-config-prettier eslint-import-resolver-webpack eslint-plugin-import eslint-plugin-prettier lint-staged prettier stylelint stylelint-config-standard --dev"
  copy_file ".eslintrc"
  copy_file ".stylelintrc"
  run "yarn add normalize.css"
end

def setup_gems
  run "spring stop"
  setup_bullet
  setup_active_storage if @active_storage
  setup_erd
  setup_sidekiq
  setup_rubocop
  setup_brakeman
  setup_guard
  setup_devise if @devise
  setup_active_admin if @active_admin
  setup_webpack
  setup_rollbar
  setup_overcommit
end

def setup_bullet
  insert_into_file "config/environments/development.rb", before: /^end/ do
    <<-RUBY
  Bullet.enable = true
  Bullet.alert = true
    RUBY
  end
end

def setup_active_storage
  run "rails active_storage:install"
end

def setup_erd
  run "rails g erd:install"
  append_to_file ".gitignore", "erd.pdf"
end

def setup_sidekiq
  run "bundle binstubs sidekiq"
  append_to_file "Procfile.dev", "worker: bundle exec sidekiq -C config/sidekiq.yml\n"
  append_to_file "Procfile", "worker: bundle exec sidekiq -C config/sidekiq.yml\n"
end

def setup_rubocop
  run "bundle binstubs rubocop"
  copy_file ".rubocop"
  copy_file ".rubocop.yml"
  run "rubocop"
end

def setup_brakeman
  run "bundle binstubs brakeman"
end

def setup_guard
  run "bundle binstubs guard"
  run "guard init livereload bundler"
  append_to_file "Procfile.dev", "guard: bundle exec guard\n"
  insert_into_file "config/environments/development.rb", "  config.middleware.insert_after ActionDispatch::Static, Rack::LiveReload\n", before: /^end/
end

def setup_devise
  run "rails g devise:install"
  insert_into_file "config/routes.rb", after: /draw do\n/ do
    <<-RUBY
  require "sidekiq/web"
  mount Sidekiq::Web => '/sidekiq'
    RUBY
  end

  insert_into_file "config/initializers/devise.rb", "  config.secret_key = Rails.application.credentials.secret_key_base\n", before: /^end/
  if @devise_user
    run "rails g devise User first_name last_name"
    append_to_file "db/seeds.rb", "User.create!(email: 'user@codelation.com', password: 'password123', first_name: 'Jon', last_name: 'Doe') if Rails.env.development? && User.count.zero?"
    insert_into_file "app/controllers/application_controller.rb", "  before_action :authenticate_user!\n", after: /exception\n/
    insert_into_file "app/controllers/pages_controller.rb", "  skip_before_action :authenticate_user!, only: :home\n", after: /ApplicationController\n/
  end
  if @devise_admin_user
    run "rails g devise AdminUser"
    append_to_file "db/seeds.rb", "AdminUser.create!(email: 'admin@codelation.com', password: 'password123') if Rails.env.development? && AdminUser.count.zero?"
  end
  run "rails g devise:views"
end

def setup_active_admin
  run "rails generate active_admin:install"
end

def setup_webpack
  run "yarn upgrade"
  run "rails webpacker:install"
  run "yarn add stimulus"
  run "yarn add rails-ujs"
end

# def setup_rollbar
#   run "rails g rollbar"
# end

def git_repo_url
  @git_repo_url ||=
    ask_with_default("What is the git remote URL for this project?", "skip")
end

def ask_with_default(question, default)
  return default unless $stdin.tty?

  question = (question.split("?") << " [#{default}]?").join
  answer = ask(question)
  answer.to_s.strip.empty? ? default : answer
end

def git_repo_specified?
  git_repo_url != "skip" && !git_repo_url.strip.empty?
end

def preexisting_git_repo?
  @preexisting_git_repo ||= (File.exist?(".git") || :nope)
  @preexisting_git_repo == true
end

def any_local_git_commits?
  system("git log &> /dev/null")
end

def setup_overcommit
  run "overcommit --install"
  copy_file ".overcommit.yml", force: true
  run "overcommit --sign"
end

apply_template!
