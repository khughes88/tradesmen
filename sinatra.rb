require 'sinatra'
require 'mongo'
include Mongo

set :bind, '0.0.0.0'
set  :port, 8080
set :public_folder, File.dirname(__FILE__)+"/"

get '/' do
 erb :main  
end

get '/mint' do
  
  db = Connection.new.db('ledger')
  bal = db['balances']
	trans = db['transactions']
  @balance=sprintf("%0.2f",bal.find( :wallet => 'mint' ).first['balance'])
  @trans=trans.find(:sender=>'mint').sort( { date: -1 } )
  erb :mint 
end

get '/bank_paylist/:wallet' do |wallet|

    if wallet=='' then
     redirect '/mint'
else
db = Connection.new.db('ledger')
bal = db['balances']

  @wallet=wallet
      @recipients=bal.find({ :wallet => 'bank' } )
end 
 erb :bank_paylist
end	
	
	
	
get '/mint_create/:wallet' do |wallet|

    if wallet=='' then
     redirect '/mint'
else
      @wallet=wallet  
end 
      erb :mint_create
end     
    
post '/mint_create/:wallet' do |wallet|
if numeric?(params[:amount]) then
db = Connection.new.db('ledger')
bal = db['balances']
#trans = db['transactions']

  bal.update( { :wallet => wallet },{ '$inc'=> { :balance=> params[:amount].to_f } } )
 # entry = {:sender=>wallet, :recipient => recipient, :sender_name=> sender['firstname']+' '+sender['surname'], :recipient_name=> recip['firstname']+' '+recip['surname'], :amount => params[:amount], :date=> Date.today.to_s }
 #  post_id = trans.insert(entry)
end  
    redirect '/mint'
end     

get '/mint_pay/:wallet/:recipient' do |wallet,recipient|

    if wallet=='' then
     redirect '/mint'
else
db = Connection.new.db('ledger')
bal = db['balances']

  @wallet=wallet
  @recipient=recipient
   result = bal.find( :wallet => recipient ).first

  @firstname=result['firstname']
  @surname=result['surname']    
end 
 erb :mint_pay
end  


	
post '/mint_pay/:wallet/:recipient' do |wallet,recipient|
if numeric?(params[:amount]) then
db = Connection.new.db('ledger')
bal = db['balances']
trans = db['transactions']
  
  recip = bal.find( :wallet => recipient ).first  
  sender=bal.find( :wallet => wallet ).first  
  funds = sender['balance']

  if funds.to_f>=params[:amount].to_f then
  bal.update( { :wallet => recipient },{ '$inc'=> { :balance=> params[:amount].to_f } } )
  bal.update( { :wallet => wallet },{ '$inc'=> { :balance=> -params[:amount].to_f } } )
 entry = {:sender=>wallet, :recipient => recipient, :sender_name=> sender['firstname']+' '+sender['surname'], :recipient_name=> recip['firstname']+' '+recip['surname'], :amount => params[:amount], :date=> Time.now }
 post_id = trans.insert(entry)
  end
end  
  redirect '/mint'
end  

get '/bank' do
	
	db = Connection.new.db('ledger')
  bal = db['balances']
  trans=db['transactions']
  @balance=sprintf("%0.2f",bal.find( :wallet => 'bank' ).first['balance'])
  @trans=trans.find('$or'=> [{:sender=> 'bank'},{:recipient=>'bank'}]).sort( { date: -1 } )
  erb :bank
 
	
end

get '/central_bank' do
  db = Connection.new.db('ledger')
  bal = db['balances']
  balances=bal.find()
  @circ=0
  @bank=sprintf("%0.2f",bal.find( :wallet => 'bank' ).first['balance'])
  balances.each{|item|
    @circ=@circ+item['balance']
    }
  @circ=sprintf("%0.2f",@circ)
  erb :central_bank
end


get '/mobile_create_wallet' do
  erb :mobile_create_wallet
end

get '/mobile' do 
   redirect '/mobile_login'
end

get '/mobile/:wallet' do |wallet|

db = Connection.new.db('ledger')
bal = db['balances']


if wallet=='' then
     redirect '/mobile_login'
else
  @wallet=wallet
  @firstname='-'
  @surname='-'
  @balance='-'
  @elec_balance='-'
  result = bal.find( :wallet => wallet ).first
  @elec_balance=sprintf("%0.2f",result['elec_balance'].to_f)
  @balance=sprintf("%0.2f",result['balance'].to_f)
  @firstname=result['firstname']
  @surname=result['surname']
end

 erb :mobile_account
end
 
  
get '/mobile_trans/:wallet' do |wallet|

db = Connection.new.db('ledger')
bal = db['balances']
trans = db['transactions']

  @wallet=wallet
  balance = bal.find( :wallet => wallet ).first
  @balance=sprintf("%0.2f",balance['balance'].to_f)
  
  @trans=trans.find('$or'=> [{:sender=> @wallet},{:recipient=>@wallet}]).sort( { date: -1 } )
 
 erb :mobile_trans
end  
  

get '/mobile_paylist/:wallet' do |wallet|

    if wallet=='' then
     redirect '/mobile_login'
else
db = Connection.new.db('ledger')
bal = db['balances']

  @wallet=wallet
      @recipients=bal.find( :wallet => { '$nin'=> [wallet,'bank','mint','central_bank'] } )
end 
 erb :mobile_paylist
end

get '/mobile_pay/:wallet/:recipient' do |wallet,recipient|

    if wallet=='' then
     redirect '/mobile_login'
else
db = Connection.new.db('ledger')
bal = db['balances']

  @wallet=wallet
  @recipient=recipient
      recip = bal.find( :wallet => recipient ).first
      @firstname=recip['firstname']
      @surname=recip['surname']  
     
end 
 erb :mobile_pay
end    

get '/mobile_topup/:wallet' do |wallet|

    if wallet=='' then
     redirect '/mobile_login'
else
      @wallet=wallet  
end 
 erb :mobile_topup
end     
 

       
get '/mobile_withdraw/:wallet' do |wallet|

    if wallet=='' then
     redirect '/mobile_login'
else
      @wallet=wallet
end 
      erb :mobile_withdraw
end      

post '/mobile_topup/:wallet' do |wallet|
if numeric?(params[:amount]) then
db = Connection.new.db('ledger')
bal = db['balances']
trans = db['transactions']
  funds = bal.find( :wallet => wallet ).first['elec_balance']
  recip = bal.find( :wallet => wallet ).first
  if funds.to_f>=params[:amount].to_f then
  bal.update( { :wallet => 'bank' },{ '$inc'=> { :balance=> -params[:amount].to_f } } ) 
  bal.update( { :wallet => wallet },{ '$inc'=> { :elec_balance=> -params[:amount].to_f } } )
  bal.update( { :wallet => wallet },{ '$inc'=> { :balance=> params[:amount].to_f } } )
    entry = {:sender=>'bank', :recipient => wallet, :sender_name=> 'Bank', :recipient_name=> recip['firstname']+' '+recip['surname'], :amount => params[:amount], :date=> Time.now }
  post_id = trans.insert(entry)
  end 
end  
    redirect '/mobile/'+wallet
end        

post '/mobile_withdraw/:wallet' do |wallet|
if numeric?(params[:amount]) then
db = Connection.new.db('ledger')
bal = db['balances']
trans = db['transactions']
   funds = bal.find( :wallet => wallet ).first['balance']
  sender = bal.find( :wallet => wallet ).first
  if funds.to_f>=params[:amount].to_f then 
  bal.update( { :wallet => 'bank' },{ '$inc'=> { :balance=> -params[:amount].to_f } } ) 
  bal.update( { :wallet => wallet },{ '$inc'=> { :elec_balance=> params[:amount].to_f } } )
  bal.update( { :wallet => wallet },{ '$inc'=> { :balance=> -params[:amount].to_f } } )
  entry = {:sender=>wallet, :recipient => 'bank', :sender_name=> sender['firstname']+' '+sender['surname'], :recipient_name=> 'Bank', :amount => params[:amount], :date=> Time.now }
 post_id = trans.insert(entry)
  end
end  
    redirect '/mobile/'+wallet
end     
      
      
def numeric?(object)  true if Float(object) rescue false end    
    


post '/mobile_pay/:wallet/:recipient' do |wallet,recipient|
if numeric?(params[:amount]) then
db = Connection.new.db('ledger')
bal = db['balances']
trans = db['transactions']
  
  recip = bal.find( :wallet => recipient ).first  
  sender=bal.find( :wallet => wallet ).first  
  funds = bal.find( :wallet => wallet ).first['balance']
  if funds.to_f>=params[:amount].to_f then 
  bal.update( { :wallet => recipient },{ '$inc'=> { :balance=> params[:amount].to_f } } )
  bal.update( { :wallet => wallet },{ '$inc'=> { :balance=> -params[:amount].to_f } } )
  entry = {:sender=>wallet, :recipient => recipient, :sender_name=> sender['firstname']+' '+sender['surname'], :recipient_name=> recip['firstname']+' '+recip['surname'], :amount => params[:amount], :date=> Time.now }
   post_id = trans.insert(entry)
  end
redirect '/mobile/'+wallet
end  
  redirect '/mobile_pay/'+wallet+'/'+recipient 
end  

post '/mobile_create' do
db = Connection.new.db('ledger')
bal = db['balances']
trans = db['transactions']
 #  o = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten
#   wallet = (0...10).map { o[rand(o.length)] }.join
  wallet=params[:id]
  entry = {:wallet=>wallet, :firstname => params[:firstname], :surname => params[:surname],:password =>             'password', :balance => 100 }
   post_id = bal.insert(entry)
   
   redirect 'mobile/'+wallet
end


post '/mobile_login' do
 redirect '/mobile/'+params[:id]
end

get '/mobile_login' do
   db = Connection.new.db('ledger')
bal = db['balances'] 
    @users=bal.find( :wallet => { '$nin'=> ['bank','mint','central_bank'] } )
 erb :mobile_login
end   
			

__END__

@@ main

  <div data-role="header" data-theme="b">
 
  <h1>Main Menu</h1>	
  
  </div>
  <div data-role="main" class="ui-content" data-theme="b">
      <ul data-role="listview" data-inset="true">
      <li data-theme="b"><a href="/mobile">Consumer / Mobile Wallet</a></li>
	<li data-theme="b"><a href="/bank">Bank</a></li>
      <li data-theme="b"><a href="/mint">Mint</a></li>
      <li data-theme="b"><a href="/central_bank">Central Bank</a></li>
</ul> 
    
  </div>

      <div data-role="footer"  data-theme="b" data-position="fixed">
      &nbsp;
</div> 
 



@@ central_bank

    <div data-role="header" data-theme="a">
      <a href="/" data-icon="home" data-mini="true">Menu</a>
  <a href="#" onClick="window.location.reload()" data-icon="refresh" data-mini="true">Refresh</a>
  <h1>Central Bank</h1>	
  
  </div>
      <div data-role="main" class="ui-content" data-theme="d">
  
  </div>
     
        <ul data-role="listview" data-inset="true" data-theme="d" style="margin-left:10px;margin-right:10px;">
      <li style="background:white;color:gray;" ><b>Digital money in circulation</b> </li>
      <li>$<%=@circ%></li>        
  </ul>
<br><br>
<ul data-role="listview" data-inset="true" data-theme="d" style="margin-left:10px;margin-right:10px;">
      <li style="background:white;color:gray;" ><b>Digital money in Bank Vault</b> </li>
      <li>$<%=@bank%></li>        
  </ul>
<div data-role="footer"  data-theme="a" data-position="fixed">
      &nbsp;
</div> 
   


@@ bank
		
  <div data-role="header" data-theme="b">
         <a href="/" data-icon="home" data-mini="true">Menu</a>
  <a href="#" onClick="window.location.reload()" data-icon="refresh" data-mini="true">Refresh</a>
   
  <h1>Bank</h1>	
  
  </div>
  <div data-role="main" class="ui-content" data-theme="b">
    
    
  </div>
     
   
 <ul data-role="listview" data-inset="true" data-theme="b" style="margin-left:10px;margin-right:10px;">
      <li style="background:white;color:gray;" ><b>Digital Vault</b> </li>
      <li> Balance: <span style="font-size:20px;font-weight:bold;";>$<%=@balance%></span> 

 </li>     
      
</ul>

		<div data-role="main" class="ui-content" data-theme="e">
    <p>Transactions: </p>
    <ul data-role="listview" data-theme="g">
     <%@trans.each{|item|%>
<li><div> <%=item['date']%> <span style="color:<%if @wallet==item['sender'] then%>red<%else%>green<%end%>;"> <b>$<%=sprintf("%0.2f",item['amount'])%></b></span><br> <%=item['sender_name']%> => <%=item['recipient_name']%> </div></li>  
     <%}%>
    </ul>  
  </div>

      <div data-role="footer"  data-theme="b" data-position="fixed">
      &nbsp;
</div> 
   
@@ mint_pay


  
<div data-role="header" data-theme="e">
<a href="/mint" data-icon="home" data-mini="true">Home</a>
				<h1>Mint</h1>	
  
  
  </div>
      <form action="/mint_pay/mint/<%=@recipient%>" method="post">
         <div data-role="main" class="ui-content" data-theme="e">
      <p>Paying : <%=@firstname%> <%=@surname%></p> 
    <div data-role="fieldcontain">
    <label for="amount">Amount:</label>
    <input type="text" name="amount" id="id" value=""  />
    
</div>	
  </div>
        <button data-role="button" data-theme="e" data-icon="arrow-r" data-iconpos="right">Pay</button>
     </form>
 
      <div data-role="footer" data-theme="e" data-position="fixed">
   &nbsp;
  </div>


@@ mint_create

      <div data-role="header" data-theme="e">
<a href="/mint" data-icon="home" data-mini="true">Home</a>
				<h1>Mint</h1>	
  </div>
			
		
      <form action="/mint_create/mint" method="post">
				<div data-role="main" class="ui-content" data-theme="b">
						<p> Currency: </p> 
							<div data-role="fieldcontain">
								<label for="amount">Amount:</label>
									<input type="text" name="amount" id="id" value=""/>
							</div>	
				</div>
								<button data-role="button" data-theme="e" data-icon="arrow-r" data-iconpos="right">Submit</button>
     </form>
 
    <div data-role="footer" data-theme="b" data-position="fixed">
   &nbsp;
  </div>

    
@@ mint

      <div data-role="header" data-theme="e">
      <a href="/" data-icon="home" data-mini="true">Menu</a>
  <a href="#" onClick="window.location.reload()" data-icon="refresh" data-mini="true">Refresh</a>
  <h1>Mint</h1>	
  
  </div>
      <div data-role="main" class="ui-content" data-theme="e">
    
    
  </div>
     
    <ul data-role="listview" data-inset="true" data-theme="e" style="margin-left:10px;margin-right:10px;">
      <li style="background:white;color:gray;" ><b>Mint</b> </li>
      <li> Balance: <span style="font-size:20px;font-weight:bold;";>$<%=@balance%></span> 
<center><div data-role="controlgroup" data-type="horizontal" data-mini="true" >
      
        <a href="/mint_create/mint" data-theme="b" data-role="button" data-icon="plus" data-mini="true" data-iconpos="right">Mint Currency</a>
    
      </div></center>
 </li>     
    
 <li>   <a href="/bank_paylist/mint" data-theme="e"  data-icon="arrow-r" data-mini="true" data-iconpos="right">Deliver Currency</a>
</li>
      
</ul>
					<div data-role="main" class="ui-content" data-theme="e">
    <p>Transactions: </p>
    <ul data-role="listview" data-theme="g">
     <%@trans.each{|item|%>
<li><div> <%=item['date']%> <span style="color:<%if @wallet==item['sender'] then%>red<%else%>green<%end%>;"> <b>$<%=sprintf("%0.2f",item['amount'])%></b></span><br> <%=item['sender_name']%> => <%=item['recipient_name']%> </div></li>  
     <%}%>
    </ul>  
  </div>
        <div data-role="footer"  data-theme="e" data-position="fixed">
      &nbsp;
</div> 
   
   
@@ mobile_login

      <div data-role="header" data-theme="b">
        <a href="/" data-icon="home" data-mini="true">Menu</a>
				<h1>Mobile Banking</h1>	

  
  </div>
    <form action="/mobile_login" method="post">
         <div data-role="main" class="ui-content" data-theme="b">
      <p>Log in as:</p> 
      <div data-role="fieldcontain">
        <label for="id" class="select">Name:</label>
            <select name="id" id="id">
            <%@users.each{|item|%>       
          
<option value="<%=item['wallet']%>"><%=item['firstname']%> <%=item['surname']%></option>

              <%}%>     
  </select>

  </div>	
    </div>
            <button data-role="button" data-theme="b">Submit</button>
       </form>

   <div data-role="footer" data-theme="b" data-position="fixed">
   &nbsp;
  </div>



@@ mobile_trans


  <div data-role="header" data-theme="b">
<a href="/mobile/<%=@wallet%>" data-icon="home" data-mini="true">Home</a>
				<h1>Mobile Banking</h1>	
<a href="/mobile_login" data-icon="arrow-r" data-mini="true" data-iconpos="right">Logout</a>  
  
  </div>
  <div data-role="main" class="ui-content" data-theme="b">
    <p>Transactions: </p>
    <ul data-role="listview" data-theme="g">
     <%@trans.each{|item|%>
<li><div> <%=item['date']%> <span style="color:<%if @wallet==item['sender'] then%>red<%else%>green<%end%>;"> <b>$<%=sprintf("%0.2f",item['amount'])%></b></span><br> <%=item['sender_name']%> => <%=item['recipient_name']%> </div></li>  
     <%}%>
    </ul>  
  </div>
  
   <div data-role="footer" data-theme="b" data-position="fixed">
   &nbsp;
  </div>


@@ mobile_paylist

  <div data-role="header" data-theme="b">
<a href="/mobile/<%=@wallet%>" data-icon="home" data-mini="true">Home</a>
				<h1>Mobile Banking</h1>	
<a href="/mobile_login" data-icon="arrow-r" data-mini="true" data-iconpos="right">Logout</a>  
  
  </div>
  <div data-role="main" class="ui-content" data-theme="b">
      <p>Scan new recipient: </p>  
    <a data-theme="e" data-role="button" href="/mobile_pay/<%=@wallet%>/coffee" data-icon="video" data-mini="true" data-iconpos="right">Scan</a>  
    
    
    <p>Choose stored recipient: </p>
    <ul data-role="listview" data-theme="g">
     <%@recipients.each{|item|%>
<%if item['wallet'] != @wallet then%>
       <li  class="ui-btn ui-shadow ui-corner-all ui-btn-icon-left ui-icon-star" ><a href="/mobile_pay/<%=@wallet%>/<%=item['wallet']%>">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<%=item['firstname']%> <%=item['surname']%></a></li> 
       <%end%> 
     <%}%>
    </ul>  
  </div>
    
   <div data-role="footer" data-theme="b" data-position="fixed">
   &nbsp;
  </div>


@@ bank_paylist

       <div data-role="header" data-theme="e">
<a href="/mint" data-icon="home" data-mini="true">Home</a>
				<h1>Mint</h1>	
  </div>
  <div data-role="main" class="ui-content" data-theme="b">
    
		<p>Choose target Bank: </p>
      <ul data-role="listview" data-theme="d">
     <%@recipients.each{|item|%>
<%if item['wallet'] != @wallet then%>
       <li  class="ui-btn ui-shadow ui-corner-all ui-btn-icon-left ui-icon-star" ><a href="/mint_pay/mint/<%=item['wallet']%>">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<%=item['firstname']%> <%=item['surname']%></a></li> 
       <%end%> 
     <%}%>
    </ul>  
  </div>
    
       <div data-role="footer" data-theme="e" data-position="fixed">
   &nbsp;
  </div>



@@ mobile_account



  <div data-role="header" data-theme="b">
         <a href="/mobile/<%=@wallet%>" data-icon="refresh" data-mini="true">Refresh</a>
  <h1>Mobile Banking</h1>	
<a href="/mobile_login" data-icon="arrow-r" data-mini="true" data-iconpos="right">Logout</a>  
  
  </div>
  <div data-role="main" class="ui-content" data-theme="b">
    <p>Welcome: <%=@firstname%> <%=@surname%></p>
  </div>
     
    <ul data-role="listview" data-inset="true" style="margin-left:10px;margin-right:10px;">
      <li style="background:white;color:gray;"><b>Current Account</b></li>
      <li> 
    Balance: <span style="font-size:20px;font-weight:bold;";>$<%=@elec_balance%></span>
    </li>
</ul>
    <br><br>
   

  <ul data-role="listview" data-inset="true" data-theme="e" style="margin-left:10px;margin-right:10px;">
      <li style="background:white;color:gray;" ><b>Digital Wallet</b> </li>
      <li> Balance: <span style="font-size:20px;font-weight:bold;";>$<%=@balance%></span> 
<center><div data-role="controlgroup" data-type="horizontal" data-mini="true" >
      
    <a href="/mobile_topup/<%=@wallet%>" data-theme="b" data-role="button" data-icon="plus" data-mini="true" data-iconpos="right">Top Up</a>
      <a href="/mobile_withdraw/<%=@wallet%>" data-theme="b" data-role="button" data-icon="minus" data-mini="true" data-iconpos="right">Withdraw</a>
     <a href="/mobile_trans/<%=@wallet%>" data-theme="b" data-role="button" data-icon="info" data-mini="true" data-iconpos="right">History</a>

      </div></center>
 </li>     
    
 <li>   <a href="/mobile_paylist/<%=@wallet%>" data-theme="e"  data-icon="arrow-r" data-mini="true" data-iconpos="right">Pay</a>
</li>
      
</ul>



      <div data-role="footer"  data-theme="b" data-position="fixed">
      &nbsp;
</div> 
   
   
  
@@ mobile_pay


  
 <div data-role="header" data-theme="b">
<a href="/mobile/<%=@wallet%>" data-icon="home" data-mini="true">Home</a>
				<h1>Mobile Banking</h1>	
<a href="/mobile_login" data-icon="arrow-r" data-mini="true" data-iconpos="right">Logout</a>  
  
  </div>
      <form action="/mobile_pay/<%=@wallet%>/<%=@recipient%>" method="post">
  <div data-role="main" class="ui-content" data-theme="b">
      <p>Paying : <%=@firstname%> <%=@surname%></p> 
    <div data-role="fieldcontain">
    <label for="amount">Amount:</label>
    <input type="text" name="amount" id="id" value=""  />
    
</div>	
  </div>
        <button data-role="button" data-theme="e" data-icon="arrow-r" data-iconpos="right">Pay</button>
     </form>
 
    <div data-role="footer" data-theme="b" data-position="fixed">
   &nbsp;
  </div>



@@ mobile_withdraw


  
 <div data-role="header" data-theme="b">
<a href="/mobile/<%=@wallet%>" data-icon="home" data-mini="true">Home</a>
				<h1>Mobile Banking</h1>	
<a href="/mobile_login" data-icon="arrow-r" data-mini="true" data-iconpos="right">Logout</a>  
  
  </div>
        <form action="/mobile_withdraw/<%=@wallet%>" method="post">
  <div data-role="main" class="ui-content" data-theme="b">
      <p>Withdrawing to : Current Account</p> 
    <div data-role="fieldcontain">
    <label for="amount">Amount:</label>
    <input type="text" name="amount" id="id" value=""  />
    
</div>	
  </div>
        <button data-role="button" data-theme="e" data-icon="arrow-r" data-iconpos="right">Withdraw
      </button>
     </form>
 
    <div data-role="footer" data-theme="b" data-position="fixed">
   &nbsp;
  </div>
      
      
@@ mobile_topup


  
 <div data-role="header" data-theme="b">
<a href="/mobile/<%=@wallet%>" data-icon="home" data-mini="true">Home</a>
				<h1>Mobile Banking</h1>	
<a href="/mobile_login" data-icon="arrow-r" data-mini="true" data-iconpos="right">Logout</a>  
  
  </div>
      <form action="/mobile_topup/<%=@wallet%>" method="post">
  <div data-role="main" class="ui-content" data-theme="b">
      <p>Topping up from : Current Account</p> 
    <div data-role="fieldcontain">
    <label for="amount">Amount:</label>
    <input type="text" name="amount" id="id" value=""  />
    
</div>	
  </div>
        <button data-role="button" data-theme="e" data-icon="arrow-r" data-iconpos="right">Submit</button>
     </form>
 
    <div data-role="footer" data-theme="b" data-position="fixed">
   &nbsp;
  </div>
    
      
      

   
     
@@ mobile_create_wallet

  <div data-role="header" data-theme="a">
    <h1>Mobile Banking</h1>
  </div>
  <form action="/mobile_create" method="post">
  <div data-role="main" class="ui-content" data-theme="a">
    <p>Create your wallet:</p> 
    <div data-role="fieldcontain">
    <label for="firstname">First name:</label>
    <input type="text" name="firstname" id="firstname" value=""  />
      </div>
     <div data-role="fieldcontain">
    <label for="surname">Surname:</label>
    <input type="text" name="surname" id="surname" value=""  />
</div>	
      <div data-role="fieldcontain">
        <label for="password">Wallet ID:</label>
            <input type="text" name="id" id="id" value=""  />
</div>	
  </div>
  <button class="ui-btn ui-corner-all" data-theme="a">Create</button>
     </form>
  <form action="/mobile_login" method="get">
  <button class="ui-btn ui-corner-all" data-theme="a">Sign In</button>
     </form>
  <div data-role="footer" data-theme="b" data-position="fixed">
   &nbsp;
  </div>

			
@@ layout
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1">
<link rel="stylesheet" href="http://code.jquery.com/mobile/1.4.0/jquery.mobile-1.4.0.min.css" />
<link rel="stylesheet" href="css/themes/theme1.css" />
  <link rel="stylesheet" href="css/themes/jquery.mobile.icons.min.css" />
<script src="http://code.jquery.com/jquery-1.10.2.min.js"></script>
<script src="http://code.jquery.com/mobile/1.4.2/jquery.mobile-1.4.2.min.js"></script>
    
 </head>
 <body>
   
    <div data-role="page" data-theme="b"  style="background-image: url('http://subtlepatterns.com/patterns/crossword.png');" >
			
			<%= yield %>
</div> 
   
 </body>
</html>

		
		