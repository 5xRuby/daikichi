# frozen_string_literal: true
RSpec.shared_examples 'authorization failed' do
  it 'should be redirected to homepage' do
    expect(subject).to have_http_status :redirect
    expect(response).to redirect_to root_path
  end
end
