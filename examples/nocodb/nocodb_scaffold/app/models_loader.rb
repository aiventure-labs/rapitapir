# frozen_string_literal: true

Dir[File.expand_path('models/**/*.rb', __dir__)].sort.each { |f| require f }
