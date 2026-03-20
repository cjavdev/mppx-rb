# frozen_string_literal: true

module Mppx
  module Expires
    module_function

    def seconds(n)
      format_time(Time.now.utc + n)
    end

    def minutes(n)
      format_time(Time.now.utc + (n * 60))
    end

    def hours(n)
      format_time(Time.now.utc + (n * 3600))
    end

    def days(n)
      format_time(Time.now.utc + (n * 86_400))
    end

    def weeks(n)
      format_time(Time.now.utc + (n * 7 * 86_400))
    end

    def months(n)
      format_time(Time.now.utc + (n * 30 * 86_400))
    end

    def years(n)
      format_time(Time.now.utc + (n * 365 * 86_400))
    end

    def format_time(time)
      time.strftime("%Y-%m-%dT%H:%M:%S.%3NZ")
    end
  end
end
