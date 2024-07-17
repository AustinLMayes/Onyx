module Onyx
end

Dir[File.dirname(__dir__) + '/lib/onyx/*.rb'].each do |file|
  require "onyx/" + File.basename(file, File.extname(file))
end

Dir[File.dirname(__dir__) + '/lib/onyx/models/*.rb'].each do |file|
  require "onyx/models/" + File.basename(file, File.extname(file))
end
