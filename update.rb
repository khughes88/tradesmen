require 'nokogiri'
require 'open-uri'
require 'mongo'
include Mongo

@client=MongoClient.new('localhost',27017)
@db=@client['oo']
@towns=@db['towns']

shop='Tesco'
 p shop
tryme=@towns.find_one({'name'=>shop})
p tryme
if !tryme then

p @towns.insert({'name'=>shop})

end
