namespace :db do
 namespace :test do
   desc "TEST: Drop the database, recreate the database, load the schema, and initialize with the seed data (use db:reset to also drop the database first)"
   task :reset do
     system("rake db:reset RAILS_ENV=test")
   end

   desc "TEST: Create the database, load the schema, and initialize with the seed data (use db:reset to also drop the database first)"
   task :setup do
     system("rake db:setup RAILS_ENV=test")
   end

   desc "TEST: Load the seed data from db/seeds.rb"
   task :seed do
     system("rake db:seed RAILS_ENV=test")
   end
 end
end
