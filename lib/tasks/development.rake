desc "Start the server in development mode"
task start: :environment do
 `open /Applications/Postgres.app`
 exec "foreman start -f ./Procfile.development"
end
