### Codelation Rails 5 Project Template

## Requirements
 - Rails 5.2
 - Ruby 2.5.1
 
 ## To Use
 - Ensure ruby version is set in terminal ```chruby ruby-2.5.1```
 - Run: ```rails new [project_name] -d postgresql -m https://raw.githubusercontent.com/codelation/rails-5-template/master/template.rb -T```, replace [project_name] with the name of the project.
 - You will be asked a series of questions for customization, answer `Yes` or `y` , `No` or `n`
 - `ss` to start server
 
 ## Specifications
 - ActiveStorage defaults for Amazon S3 in production
 - Devise User and AdminUser default accounts use regular Codelation account email and password combinations
 - User has first_name and last_name by default
