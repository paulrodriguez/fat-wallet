DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite://"+File.dirname(__FILE__)+"/FatWallet.db")


Dir.glob('./models/*.rb').each { |file| require_relative file }








DataMapper.auto_upgrade!
