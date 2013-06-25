require 'spec_helper'

describe 'AwestructWebEditor' do
  it do
    get '/repo/test_repo'
    last_response.should be_ok
    pending "Finish the implementation"
  end
end
