title 'Test single GCP Zone'

gcp_project_id = attribute(:gcp_project_id, default: '', description: 'The GCP project identifier.')
gcp_kube_cluster_zone = attribute(:gcp_kube_cluster_zone, default: '', description: 'The GKE cluster zone.')
gcp_kube_cluster_zone_extra1 = attribute(:gcp_kube_cluster_zone_extra1, default: '', description: 'The GKE cluster secondary zone.')
gcp_kube_cluster_zone_extra2 = attribute(:gcp_kube_cluster_zone_extra2, default: '', description: 'The GKE cluster tertiary zone.')


control 'gcp-single-zone-1.0' do

  impact 1.0
  title 'Ensure single zone has the correct properties.'

  describe google_compute_zone(project: gcp_project_id, name: gcp_kube_cluster_zone) do
    it { should be_up }
  end

  describe google_compute_zone(project: gcp_project_id, name: gcp_kube_cluster_zone_extra1) do
    it { should be_up }
  end

  describe google_compute_zone(project: gcp_project_id, name: gcp_kube_cluster_zone_extra2) do
    it { should be_up }
  end
end