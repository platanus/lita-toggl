module Lita
  module Clients
    class Harvest
      API_URL = "https://api.harvestapp.com/api/v2"

      attr_reader :account_id, :token

      def initialize(account_id, token)
        @account_id = account_id
        @token = token
      end

      def users_current_entries
        get_users.map do |user|
          activity_data = get_user_activity_data(user["id"])
          data = {
            user_name: get_user_fullname(user),
            user_email: user["email"]
          }

          if !!activity_data
            data[:project_name] = get_project_name(activity_data)
            data[:description] = get_activity_description(activity_data)
            data[:started_at] = get_acivity_start_time(activity_data)
          end

          UserTimeEntry.new(data)
        end
      end

      private

      def auth_headers
        {
          "Authorization" => "Bearer #{token}",
          "Harvest-Account-Id" => account_id
        }
      end

      def get_activity_description(activity_data)
        [
          activity_data["task"]["name"], activity_data["notes"]
        ].compact.join(": ")
      end

      def get_project_name(activity_data)
        [
          activity_data["client"]["name"], activity_data["project"]["name"]
        ].compact.join(" - ")
      end

      def get_user_fullname(user)
        [user["first_name"], user["last_name"]].compact.join(" ")
      end

      def get_user_activity_data(user_id)
        get_time_entries.find do |entry|
          entry["user"]["id"] == user_id
        end
      end

      def get_acivity_start_time(activity_data)
        return unless activity_data["started_at"]
        Time.parse(activity_data["started_at"]).localtime
      end

      def get_time_entries
        return @time_entries if @time_entries
        result = get("time_entries")
        return [] unless result
        @time_entries = result["time_entries"]
      end

      def get_users
        users = get("users")
        return [] unless users
        users["users"]
      end

      def get(resource)
        resource_url = "#{API_URL}/#{resource}.json"
        response = HTTParty.get(resource_url, headers: auth_headers)
        return JSON.parse(response.body) if response.success?
      end
    end
  end
end