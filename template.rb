RAILS_REQUIREMENT = ">= 5.2.0.rc1"

def apply_template!

  add_template_repository_to_source_path

  template "Gemfile.tt", force: true

  apply "config/template.rb"
  apply "app/template.rb"
  apply "lib/template.rb"

  copy_file "Procfile"
  copy_file "Procfile.dev"

  ask_optional_options
end

def ask_optional_options
  @devise = yes?("Do you want to implement authentication in your app with the Devise gem?")
  @devise_invitable = yes?("Do you want to use invitable with devise?") if @devise
  @pdfs = yes?("Do you want to generate PDFs with this application?")
  @active_admin = yes?("Do you want to use ActiveAdmin for Admin backend?")
  @github = yes?("Do you want to push your project to Github?")
end

def install_optional_gems
  add_devise if @devise
  add_pdfs if @pdfs
  add_active_admin if @active_admin
end

def add_devise
  insert_into_file "Gemfile", "gem \"devise\"", after: /"codelation_assets"\n/
  insert_into_file "Gemfile", "gem \"devise_invitable\"", after: /"codelation_assets"\n/ if @devise_invitable
end

def add_pdfs
  insert_into_file "Gemfile", "gem \"wickedpdf\"", after: /"codelation_assets"\n/
  insert_into_file "Gemfile", "gem \"wkhtmltopdf-binary\"", after: /"codelation_assets"\n/
end

def add_active_admin
  insert_into_file "Gemfile", "gem \"activeadmin\"", after: /"codelation_assets"\n/
end

def add_template_repository_to_source_path
  if __FILE__ =~ %r{\Ahttps?://}
    source_paths.unshift(tempdir = Dir.mktmpdir("rails-template-"))
    at_exit { FileUtils.remove_entry(tempdir) }
    git :clone => [
      "--quiet",
      "https://github.com/codelation/rails-5-template",
      tempdir
    ].map(&:shellescape).join(" ")
  else
    source_paths.unshift(File.dirname(__FILE__))
  end
end

apply_template!
