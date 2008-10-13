require 'yaml'

class Merb::Test::RequestController < Merb::Controller
  provides :all
  def multipart
    self.content_type = Merb.available_accepts[params[:file_upload][:content_type]]
    {:method => request.method, :content => params[:file_upload][:tempfile].read}.to_yaml
  end
end