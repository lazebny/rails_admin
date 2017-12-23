module RailsAdmin
  module Support
    module FileHelper
      def self.require_relative(base_file, *path)
        Dir[File.join(File.dirname(base_file), *path)].each(&method(:require))
      end
    end
  end
end
