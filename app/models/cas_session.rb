require 'json'

class CasSession < ActiveResource::Base

  attr_accessor :username
  attr_writer   :password
  attr_reader   :headers
  attr_reader   :person_id
 
  self.site = COS_URL
  self.format = :json 
  self.timeout = COS_TIMEOUT
  @@app_password = "Xk4z5iZ"
  @@app_name = "kassi"
  @@cookie = nil
  
  def self.destroy(cookie)
    deleting_headers = {"Cookie" => cookie}
    connection.delete("#{prefix}#{element_name}", deleting_headers)
  end
  
  #Use only for session containing a user (NO app-only session)
  def self.get_by_cookie(cookie)
    new_session = Session.new
    new_session.cookie = cookie

    return nil unless new_session.set_person_id()   
    return new_session
  end
  
  #a general app-only session cookie that maintains an open session to Cos for Kassi
  def self.kassiCookie
    if @@cookie.nil?
      @@cookie = Session.create.cookie
    end
    return @@cookie
  end
  
  #this method can be called, if kassiCookie is not valid anymore
  def self.updateKassiCookie
    @@cookie = Session.create.cookie
  end
  
  def initialize(params={})
    self.username = params[:username]
    self.password = params[:password]
    super(params)
  end
  
  def create
    @headers = {}
    params = {}
    params[:username] = @username if @username
    params[:pt] = @password if @password
    puts @password
    params.update({:app_name => @@app_name, :app_password => @@app_password})
    resp = connection.post("#{self.class.prefix}#{self.class.element_name}", params.to_json)
    @headers["Cookie"] = resp.get_fields("set-cookie").to_s
    json = JSON.parse(resp.body)
    @person_id = json["user_id"] 
  end
  
  def check
    get("")
  end
  
  def get(path)
    begin
      return connection.get("#{self.class.prefix}#{self.class.element_name}", @headers)
    rescue ActiveResource::ResourceNotFound => e
      return nil
    rescue ActiveResource::UnauthorizedAccess => e
      return nil
    end
  end
   
  def destroy
    Session.destroy(@headers["Cookie"])
  end
  
  def cookie
    @headers["Cookie"]
  end
  
  def cookie=(cookie)
    @headers ||= {}
    @headers["Cookie"] = cookie
  end
  
  def set_person_id
    info = self.check
    return nil if info.nil?
    @person_id =  info["user_id"]
    return @person_id
  end
end