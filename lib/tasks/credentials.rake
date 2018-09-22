namespace :credentials do
 task default_edit: :environment do |t|
   exec "EDITOR='atom -w' rails credentials:edit"
 end
end
