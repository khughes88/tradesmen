require 'nokogiri'
require 'open-uri'
require 'mongo'
require 'json'
include Mongo

@client=MongoClient.new('localhost',27017)
@db=@client['oo']
@hours=@db['hours']

40000.times do
	num =rand(6)
	p num
	sleep num
  h=@hours.find_one({'url'=>nil})
  shop=h['shop']
  town=h['town']
  term= "#{shop.downcase} #{town.downcase} opening hours"
  p term
  q="http://www.google.ie/search?q=#{term}"
  encoded_url = URI.encode(q)
  begin
    doc = Nokogiri::HTML(open(encoded_url))
    results=doc.xpath('//h3[@class="r"]')
    if  results.size>0 then
      results.each{|rc|
      s=rc.text
	if ! s.valid_encoding?
	  s = s.encode("UTF-16be", :invalid=>:replace, :replace=>"?").encode('UTF-8')
	end
	title=s.downcase
	words=[shop,town,'opening']
	if title.include?(shop.downcase)&&title.include?(town.downcase)&&title.include?('opening') then
	 
	  unless title.include?('map')
		  link=rc.xpath('a').attr('href').to_s.gsub('/url?q=','')
		  p title
		  p link
		 
		  @hours.update({"shop"=>shop,"town"=>town},{"$set"=>{'url'=>link}})
		  break
	  end
	else	
	  
	  @hours.update({"shop"=>shop,"town"=>town},{"$set"=>{'url'=>'error'}})
	end	
	
      }
    else
	   
				@hours.update({"shop"=>shop,"town"=>town},{"$set"=>{'url'=>'none'}},{"upsert"=>true})
	    
    end
  rescue Exception=>e
    p e
	    
			@hours.update({"shop"=>shop,"town"=>town},{"$set"=>{'url'=>'error'}},{"upsert"=>true})
	    
    end
end	




