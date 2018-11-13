copy_file "config/initializers/generators.rb"
copy_file "config/initializers/i18n.rb"
copy_file "config/initializers/sidekiq.rb"
copy_file "config/initializers/redis.rb"
copy_file "config/application.yml"

copy_file "config/routes.rb", force: true

insert_into_file "config/environments/development.rb", after: "/config\.action_mailer\.raise_delivery_errors = false\n/" do
  <<-RUBY
    config.action_mailer.default_url_options = {host: "localhost:3000"}
    config.action_mailer.asset_host = "http://localhost:3000"
    config.default_options = {from: ENV["DEFAULT_FROM_EMAIL"]}
    config.active_storage.service = :local
  RUBY
end

copy_file "config/smtp.rb"

insert_into_file "config/environments/production.rb", before: "Rails.application.configure do\n" do
  <<-RUBY
    require Rails.root.join("config/smtp")
  RUBY
end

insert_into_file "config/environments/production.rb", after: "/config\.action_mailer\.perform_caching = false\n/" do
  <<-RUBY
    config.active_job.queue_adapter = :sidekiq
    config.action_mailer.default_url_options = {host: ENV["HOST"]}
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = SMTP_SETTINGS
    config.active_storage.service = :amazon
  RUBY
end

gsub_file "config/environments/production.rb", "/config\.assets\.js_compressor = \:uglifier\n/", "/config\.assets\.js_compressor = Uglifier\.new\(harmony\: true\)\n/"

copy_file "config/sidekiq.yml"
