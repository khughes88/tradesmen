require 'nokogiri'
require 'open-uri'
require 'mongo'
include Mongo

@client=MongoClient.new('localhost',27017)
@db=@client['oo']
@hours=@db['hours']


data=Hash.new
data['url']=nil
@hours.update({'shop'=>/Costa/},{"$set"=>data})


