Title: cas-rest-client: a rest client to interact with CASified services
Author: Antonio Marques
Date: Mon Nov 08 2010 10:38:25 GMT-0200 (PDT)
Node: v0.2.4
Categories: ruby, rest, cas

So, you need to interact programmatically with a [CASified](https://wiki.jasig.org/display/CAS/CASifying+Applications) service or API. [That's such a boring task](https://wiki.jasig.org/display/CASUM/RESTful+API). To access any resource, it's necessary to acquire a ticket-granting ticket ([TGT](http://www.jusfortechies.com/cas/protocol.html#tgt)) from [CAS](http://www.jasig.org/cas), use it to ask CAS for a service ticket ([ST](http://www.jusfortechies.com/cas/protocol.html#st)) and then pass this service ticket as a parameter to access the resource. For every request, this cycle repeats. 

For Ruby developers, the [CasRestClient gem](https://rubygems.org/gems/cas_rest_client) can be handy. Instead of coding all these ticketing interactions with CAS, just pass the CAS uri and credentials to the CasRestClient instance:

    require 'rubygems'
    require 'cas_rest_client'
    
    # CAS uri, credentials and service
    params = {:uri => 'https://cas_auth_server.com/tickets', :username => 'user', :password => 'pass', 
      :service => 'http://casified_api.com/'}
      
    client = CasRestClient.new params
    response = client.get "https://casified_api.com/resource", :accept => 'application/xml'
    
CasRestClient will handle all the interactions with CAS to acquire service tickets, and automatically will use them to access the requested resources.

## :use_cookies => ?

Once successfully authenticated on CAS, the CASified app will usually return a session cookie the first time any resource is accessed. This cookie maintains login state for the client, and while it is valid, the client can present it as primary credentials. This prevents unnecessary auth/ticketing interactions with CAS.

To enable the use of session cookies in CasRestClient, just pass __:use\_cookies => true__  in the constructor hash (this is actually the default option):

    require 'rubygems'
    require 'cas_rest_client'

    params = {:uri => 'https://cas_auth_server.com/tickets', :username => 'user', :password => 'pass', 
      :service => 'http://casified_api.com/', :use_cookies => true}
      
    client = CasRestClient.new params
    client.cookies #=> nil
    
    # will ask CAS for a service ticket, and use it
    response = client.get "https://casified_api.com/resource", :accept => 'application/xml'
    client.cookies #=> {"_api_session"=>"BAh7DCINY2FzX3VzZXIiImFudG9uaW9tYXJxdWVzL2FudG9uaW9tYXJxdWVzIg9zZXNz..."}
    
    # will use the session cookie, preventing new requests to CAS
    response = client.get "https://casified_api.com/resource2", :accept => 'application/xml'
        

## More info

For more information on CasRestClient's behaviour and configuration - like custom parameter passing and Rails integration - check out the [project's page](https://github.com/robertokl/cas-rest-client). 
