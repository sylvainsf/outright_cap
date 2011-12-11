Capistrano::Configuration.instance(:must_exist).load do
  module OutrightCap
    module CampfireNotifier
      def self.extended(base)
        base._cset(:campfire_token) { abort "Must set campfire_token in order to notify, set :campfire_token, 'token'" }
        base._cset(:campfire_speak_url) { abort "Must set the campfire speak url, set :campfire_speak_url, 'https://companyname.campfirenow.com/room/123/speak.json'" }
      end
      
      def notify(message)
        token = fetch(:campfire_token)
        system("curl -s -u #{token}:x -H 'Content-Type: application/json' -d '{\"message\": { \"body\": \"#{message} (by: #{ENV["USER"]})\" }}' #{campfire_speak_url} > /dev/null")
      end
    end
  end

  Capistrano.plugin :campfire_notifier, OutrightCap::CampfireNotifier
end
