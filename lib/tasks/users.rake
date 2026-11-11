namespace :users do
  desc "Give a user the admin role (all permissions): bin/rails \"users:make_admin[username]\""
  task :make_admin, [ :username ] => :environment do |_, args|
    user = User.find_by!(username: args[:username].to_s.strip.downcase)
    role = Role.find_or_create_by!(name: "ผู้ดูแลระบบ") { it.permissions = Role::PERMISSIONS.keys }
    user.update!(role: role)
    puts "#{user.username} is now #{role.name}"
  end
end
