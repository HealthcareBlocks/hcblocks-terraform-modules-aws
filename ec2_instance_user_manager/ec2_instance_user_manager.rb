require 'aws-sdk-ssm'
require 'aws-sdk-ec2'
require 'json'

def lambda_handler(event:, context:)
  puts event
  ssm_client = Aws::SSM::Client.new(region: ENV['AWS_REGION'])
  ec2_client = Aws::EC2::Client.new(region: ENV['AWS_REGION'])

  detail = event['detail']
  parameter_name = detail['name']
  operation = detail['operation']

  if parameter_name.start_with?('/ec2_instance')
    parts = parameter_name.split('/')
    instance_id = parts[2]
    username = parts[3]
    user_properties = {}

    if operation != "Delete"
      resp = ssm_client.get_parameter({
        name: parameter_name
      })

      # Extract user properties if available
      user_properties = JSON.parse(resp.parameter.value) rescue {}
    end

    # Ensure the instance is in a 'running' or 'pending' state
    instance_state = get_instance_state(ec2_client, instance_id)
    unless %w[running pending].include?(instance_state)
      puts "Instance #{instance_id} is not in a state to modify users: #{instance_state}"
      return { statusCode: 400, body: JSON.generate("Instance is not in a state to modify users: #{instance_state}") }
    end

    # Perform the appropriate action based on the operation
    case operation
    when 'Create'
      create_user(instance_id, username, user_properties)
    when 'Update'
      update_user(instance_id, username, user_properties)
    when 'Delete'
      delete_user(instance_id, username)
    else
      puts "Unknown operation: #{operation}"
      return { statusCode: 400, body: JSON.generate("Unknown operation: #{operation}") }
    end
  else
    puts "Parameter #{parameter_name} is not handled by this function."
    { statusCode: 406 }
  end

  { statusCode: 200, body: JSON.generate("Operation #{operation} completed for user #{username} on instance #{instance_id}") }
end

def get_instance_state(ec2_client, instance_id)
  response = ec2_client.describe_instances(instance_ids: [instance_id])
  response.reservations[0].instances[0].state.name
end

def create_user(instance_id, username, user_properties)
  commands = [
    "set -e",
    "useradd -U -m -s #{user_properties['shell']} #{username}",
    user_properties['groups'] ? user_properties['groups'].map { |group| "groupadd #{group} || true" }.join('; ') : nil,
    user_properties['groups'] ? "usermod -G #{user_properties['groups'].join(',')} #{username}" : nil,
    "mkdir -p /home/#{username}/.ssh",
    user_properties['ssh_keys'] ? user_properties['ssh_keys'].map { |key| "echo #{key} >> /home/#{username}/.ssh/authorized_keys" }.join('; ') : nil,
    "chown -R #{username}:#{username} /home/#{username}/.ssh",
    "chmod 700 /home/#{username}/.ssh",
    "chmod 600 /home/#{username}/.ssh/authorized_keys",
    user_properties['sudoer'] ? "echo '#{username} ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/#{username}" : nil
  ].compact

  run_commands(instance_id, commands)
end

def update_user(instance_id, username, user_properties)
  commands = [
    "set -e",
    "usermod -s #{user_properties['shell']} #{username}",
    user_properties['groups'] ? user_properties['groups'].map { |group| "groupadd #{group} || true" }.join('; ') : nil,
    user_properties['groups'] ? "usermod -G #{user_properties['groups'].join(',')} #{username}" : nil,
    "mkdir -p /home/#{username}/.ssh",
    "truncate -s 0 /home/#{username}/.ssh/authorized_keys",
    user_properties['ssh_keys'] ? user_properties['ssh_keys'].map { |key| "echo #{key} >> /home/#{username}/.ssh/authorized_keys" }.join('; ') : nil,
    "chown -R #{username}:#{username} /home/#{username}/.ssh",
    "chmod 700 /home/#{username}/.ssh",
    "chmod 600 /home/#{username}/.ssh/authorized_keys",
    user_properties['sudoer'] ? "echo '#{username} ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/#{username}" : "rm -f /etc/sudoers.d/#{username}"
  ].compact

  run_commands(instance_id, commands)
end

def delete_user(instance_id, username)
  commands = [
    "userdel -r #{username}",
    "rm -f /etc/sudoers.d/#{username}"
  ]

  run_commands(instance_id, commands)
end

def run_commands(instance_id, commands)
  ssm_client = Aws::SSM::Client.new(region: ENV['AWS_REGION'])

  commands.each_slice(10) do |commands_batch|
    ssm_client.send_command({
      instance_ids: [instance_id],
      document_name: 'AWS-RunShellScript',
      parameters: { commands: commands_batch }
    })
  end
end
