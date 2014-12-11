require 'nokogiri'
require 'open-uri'
require 'mongo'
include Mongo

@client=MongoClient.new('localhost',27017)
@db=@client['oo']
@hours=@db['hours']


#p @hours.count()

u=@hours.find('url'=> //)
p "total: #{u.count}"

good=0
u.each{|u|
	if u['url']!='none' && u['url']!='error'
		then 
			good+=1
			#p u['shop']+" "+u['town']
			#p u['url']
			
		end
		
}
p "good: #{good.to_s}"

