# I do always this to program:
sudo /etc/init.d/rails_daemon stop
sudo /etc/init.d/music_daemon stop
#atom &
ruby lib/music/music_daemon.rb run -- -d
