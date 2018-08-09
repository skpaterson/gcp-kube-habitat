# Configuration helper for GCP & Inspec
# - Terraform expects a JSON variable file
# - Inspec expects a YAML attribute file
# This allows to store all transient parameters in one place.
# If any of the @config keys are exported as environment variables in uppercase, these take precedence.
require 'json'
require 'yaml'
require 'passgen'

module GcpConfig

  # Config for terraform / inspec in the below hash
  @config = {
      # Generic GCP resource parameters
      :gcp_project_id => "spaterson-project",
      :gcp_location => "europe-west2",
      :gcp_zone => "europe-west2-a",
      :gcp_kube_cluster_name => "gcp-kube-cluster",
      :gcp_kube_cluster_zone => "europe-west1-d",
      :gcp_kube_cluster_zone_extra1 => "europe-west1-b",
      :gcp_kube_cluster_zone_extra2 => "europe-west1-c",
      :gcp_kube_cluster_master_user => "gcp-kube-admin",
      :gcp_kube_cluster_master_pass => Passgen::generate(length: 20, uppercase: true, lowercase: true, symbols: true, digits: true),
      :gcp_kube_nodepool_name => "default-pool",
      :hab_container_service_account_name => "hab-svc-acct-#{(0...15).map { (65 + rand(26)).chr }.join.downcase}",
      # when set to 1 this will create the service account in addition to the kube cluster
      # making configurable - not created by default
      :create_habitat_service_account => 0
  }

  def self.config
    @config
  end

  # This method ensures any environment variables take precedence.
  def self.update_from_environment
    @config.each { |k,v| @config[k] = ENV[k.to_s.upcase] || v }
  end

  # Create JSON for terraform
  def self.store_json(file_name="gcp-inspec.tfvars")
    update_from_environment
    File.open(File.join(File.dirname(__FILE__),'..','build',file_name),"w") do |f|
      f.write(@config.to_json)
    end
  end

  # Create YAML for inspec
  def self.store_yaml(file_name="gcp-inspec-attributes.yaml")
    update_from_environment
    File.open(File.join(File.dirname(__FILE__),'..','build',file_name),"w") do |f|
      f.write(@config.to_yaml)
    end
  end

end
