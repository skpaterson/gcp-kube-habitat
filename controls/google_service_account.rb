title 'IAM Service Account Properties'

gcp_project_id = attribute(:gcp_project_id, default: '', description: 'The GCP project identifier.')
hab_container_service_account_name = attribute(:hab_container_service_account_name, default: '', description: 'The GCP IAM Service Account display name.')
create_habitat_service_account = attribute(:create_habitat_service_account,default:0,description:'Flag to enable this test if the service account was created.')

control 'gcp-generic-iam-service-account' do

  only_if { create_habitat_service_account.to_i == 1 }
  impact 1.0
  title 'Ensure that the Service Account is correctly set up'

  describe google_service_account(project: gcp_project_id, name: hab_container_service_account_name ) do
    its('display_name') { should eq hab_container_service_account_name }
    its('project_id') { should eq gcp_project_id }
    its('email') { should eq "#{hab_container_service_account_name}@#{gcp_project_id}.iam.gserviceaccount.com" }
  end
end