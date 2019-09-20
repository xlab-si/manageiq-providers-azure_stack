class ManageIQ::Providers::AzureStack::Inventory::Parser::NetworkManager < ManageIQ::Providers::AzureStack::Inventory::Parser
  def parse
    log_header = "Collecting data for EMS : [#{collector.manager.name}] id: [#{collector.manager.id}]"
    $azure_stack_log.info("#{log_header}...")

    cloud_networks
    network_ports
    security_groups

    $azure_stack_log.info("#{log_header}...Complete")
  end

  def cloud_networks
    collector.networks.each do |network|
      persister.cloud_networks.build(
        :name    => network.name,
        :ems_ref => network.id.downcase
      )
      if network.subnets
        cloud_subnets(network)
      end
    end
  end

  def cloud_subnets(network)
    network.subnets.each do |subnet|
      persister.cloud_subnets.build(
        :name            => subnet.name,
        :ems_ref         => subnet.id.downcase,
        :cloud_network   => persister.cloud_networks.lazy_find(network.id.downcase),
        :security_groups => build_security_groups(subnet)
      )
    end
  end

  def network_ports
    collector.network_ports.each do |port|
      persister.network_ports.build(
        :name            => port.name,
        :ems_ref         => port.id.downcase,
        :mac_address     => port.mac_address,
        :device          => port.virtual_machine ? persister.vms.lazy_find(port.virtual_machine.id.downcase) : nil,
        :security_groups => build_security_groups(port)
      )
    end
  end

  # helper method that returns either an empty array or a one-element
  # array containing the entity's security group.
  def build_security_groups(entity)
    if entity.network_security_group
      id = entity.network_security_group.id.downcase
      [persister.security_groups.lazy_find(id)]
    else
      []
    end
  end

  def security_groups
    collector.security_groups.each do |security_group|
      persister.security_groups.build(
        :name    => security_group.name,
        :ems_ref => security_group.id.downcase
      )
    end
  end
end
