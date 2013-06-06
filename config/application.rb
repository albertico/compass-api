# Load configuration
ENVIRONMENT = 'development'
DB_CONFIG = YAML.load(ERB.new(File.read('config/database.yml')).result)[ENVIRONMENT]
API_CONFIG = YAML.load(ERB.new(File.read('config/api.yml')).result)

# Establish DB connection
ActiveRecord::Base.establish_connection(DB_CONFIG)
