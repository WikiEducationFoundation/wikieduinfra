# Wikiedu's Hashistack Setup

This repository contains the Terraform configuration for Wikiedu.

This configuration:

* **Creates a datacenter on Linode**, connected by Consul.
* **Creates a Nomad cluster**.
* **Spins up the necessary resources (redis, mariadb, memcached) for powering the [WikiEdu Rails app](https://github.com/WikiEducationFoundation/WikiEduDashboard)**.

## Steps to Spin Up a New Datacenter

### Preparation

1. If you already use `waypoint` to manage another cluster, clear the context before you begin: `waypoint context clear`. Also, make sure your contexts (found in `$/.config/waypoint`) are named well. The provisioning script will create a new context with a name like `install-#######`.

### Create and provision the servers

1. Create a `secrets.tfvars` file in the `linode` and `nomadservers` directories. See `secrets.tfvars.example` and `variables.tf` for more information.
2. Ensure all binaries (below) are on your `PATH`
3. `terragrunt run-all init`
4. `terragrunt run-all apply`
   1. This command will create all the required server nodes (`linode_instance` resources) followed by several non-Rails services (`nomad_job` and `consul_config_entry` resources).
   2. Using a `null_resource`, it will locally generate `nomad.sh`, which contains the data needed to post additional jobs (ie, the Rails jobs) to the cluster.
   3. Using a `null_resource`, it will install a waypoint server and runner onto one of the nodes. The `null_resource`s are normally only provisioned once, and then have entries in a `terraform.tfstate` file. If you need to re-run one of these, you can delete the corresponding resource entry from the `.tfstate` file.
   4. At this point, you can reach the Nomad UI by via `https://{nomad_server_ip_address}:4646`. The required ACL token Secret ID is the `nomad_mgmt_token`, also available on the Nomad server in `/root/bootstrap.token`.
5. Configure DNS
   1. Create an A record to point the **rails domain** to the nginx node's IP address
   2. Create an A record to point the **docker domain** to the nginx node's IP address
   3. Create an A record to point the **nomad domain** to the nginx node's IP address 
6. Run the provided ssl provision script (in `nomadserver` ) on the nginx node. You'll need to update the domains list and copy it to the node.
   - `ssh root@{rails domain}`
   - Copy the `provision_nginx_ssl.sh` script to the node
   - Run it: `bash provision_nginx_ssl.sh`
   - Copy the `renew_nging_ssl.sh` script to the node and run it: `bash renew_nginx_ssl.sh`. This will reload nginx and make the certs available.
   - To enable automatic cert renewals, add the provided `renew_nginx_ssl.sh` script to the server and run it weekly via crontab.

### Prepare the Rails app

7. Clone a fresh copy of the WikiEduDashboard app in a new directory
8. Create `application.yml` and `database.yml` to match what will run in the cloud. (These will be included in the Docker image that gets deployed.)
   1. The username, password, and production database name in `database.yml` must match up with the values from `mariadb.hcl.tmpl`.
   2. `application.yml` must have `hashistack: 'true'` (at least, until the `production.rb` file is set to enable public file server by default).
9.  Install the gems and node modules, then build the production assets:
   3.  `bundle install`
   4.  `yarn install`
   5.  `yarn build`
10. Log in to docker and set the credentials for use by Waypoint
    1. `docker login <DOCKER_DOMAIN>`. User: 'docker', password: same the input to `htpasswd` when generating {docker_pass_encrypted}
    2. Create `dockerAuth.json` (following the example of `dockerAuth.example.json`)
11. Add nomad variables to your ENV
    1. `source nomadserver/nomad.sh` or similar, in the same shell used for the WikiEduDashboard waypoint commands below.
12. Run `waypoint init` to generate the job templates.
13. Build and deploy
    1.  `waypoint up` generates a Docker image, pushes it to the registry, and deploys it to all the web and sidekiq jobs
    2.  `waypoint build` just generates a Docker image and pushes it to the registry at the docker domain
    3.  `waypoint deploy` just deploys the latest image as a set of jobs for web and sidekiq

### Transfer data (unless starting from scratch)

14. Copy the database
    1.  Use SCP to transfer a gzipped copy of the database to the mariadb node (after adding an SSH pubkey from the source machine to the authorized_keys file on the node.)
    2.  Copy the database file into the mariadb container using `docker copy`
    3.  Log in to the docker container (eg `docker exec -it 0323b53c064e /bin/bash`
    4.  Unzip and import the database (eg `gunzip daily_dashboard_2021-04-26_01h16m_Monday.sql.gz`; `mysql -u wiki -p dashboard < daily_dashboard_2021-04-26_01h16m_Monday.sql`)
15. Copy the `/public/system` directory to the railsweb node.
    1.  This lives at `/var/www/dashboard/shared/public/system` for the Capistrano-deployed production server.
    2.  Get it to the node: `scp -r system/ 45.33.51.69:/root/database_transfer/`
    3.  Change the permissions so that the docker user can write to it: `chmod -R 777 system`
    4.  Get it into docker: `docker cp system 13a78c00206f:/workspace/public/`

### Create database (if starting from scratch)

16. Prepare the database
    1.  Log in or exec into a rails container
    2.  `/cnb/lifecycle/launcher rails db:migrate`
17. Create the default campaign
    1.  `/cnb/lifecycle/launcher rails c`
    2.  `Campaign.create(title: 'Default Campaign', slug: ENV['default_campaign'])`

## Binaries required

1. Waypoint (0.3) - https://www.waypointproject.io/
2. Terraform (0.15) - https://www.terraform.io/
3. Terragrunt (0.28.24) - https://terragrunt.gruntwork.io/
4. Consul - https://www.consul.io/ 
5. Nomad - https://www.nomadproject.io/
6. `ssh-keyscan`, `jq`, `scp` and `htpasswd` (provided by apache2-utils on Debian)

## Interacting with Terraform resources
When Terraform spins up virtual machines, it installs your SSH keys. You can SSH directly into root@IP_ADDRESS for any of the virtual machines. The most important ones — nginx and Nomad — are shown in the outputs of `terragrunt run-all apply`. (This command is idempotent, so you can run it with no changes in the project to see the current IPs.)

### Managing resources from multiple devices
To set up a new device to manage an existing (production) cluster of resources:

1. Clone the repository
2. Add the same SSH keys used to access the cluster (as specified in `linode/secrets.tfvars`)
   1. `chmod 600` the private key after copying it, or it may not work.
   2. With just the ssh key, you should be able to `ssh root@<rails domain>`, etc.
3. Copy all required state into the project directory
   1. Both `secrets.tfvars` files
   2. All 5 `terraform.tfstate` files
   3. The entire `certs` directory
   4. `nomadserver/nomad.sh` (modify the paths to the certs if necessary)
4. Run `terragrunt run-all apply`. If this works, everything is in order.

Note that running `terragrunt run-all apply` will only apply changes it detects based on files in the project directory, so if changes have been deployed that don't match the local project (for example, changes on another computer that weren't checked into git or are from a newer revision missing from the local repo) then no running services will be changed. To reset a service (eg, the nginx gateway), you can make a nonfunctional change (ie, add a comment) to the corresponding `.hcl.tmpl` file.

### Using Waypoint Exec

You may connect to any container running the rails app with `waypoint exec` (eg, `waypoint exec bash`).

However, once inside the container, you must prefix all commands with `/cnb/lifecycle/launcher` in order to set `$PATH` correctly and get all of your actually-installed Rubies/gems/etc, rather than using the system versions.

Useful commands:
* Get a production Rails console: `/cnb/lifecycle/launcher rails console`
### Scaling Strategy

**Rails and Sidekiq workloads**: If you're running out Sidekiq capacity (queues getting backed up) or Rails capacity (HTTP queue latency reported is unacceptable, say 150milliseconds or more), you should add additional "no volume" nodes by [increasing the task group `count`](https://www.nomadproject.io/docs/job-specification/group) to provide more resources, then change the `rails` jobspec file in the WikiEdu repo or use the [nomad job scale](https://www.nomadproject.io/docs/commands/job/scale) command.
* **More NGINX capacity** If Nginx is running out of CPU, resize the node (in `linode/main.tf`). This will take about 5 minutes and will cause hard downtime. You will then need to increase the cpu/memory allocation in the Nomad jobfile for Nginx.
* **More Redis or Memcache capacity**. Update the appropriate variables that control CPU/memory allocation. If that means that you have no available space in the cluster topology, provision additional nodes in `linode/main.tf`.
* **More MariaDB capacity**. Resize the node. This will cause hard downtime of 5 minutes or more. You will need to update the cpu/memory allocation in the mariadb job spec. It is intended that the mariadb job takes all of the resources on its node.

### Backups and recovery

Linode backups are enabled for each of the nodes in our cloud, and these serve as the primary backup mechanism.

We can also use the backup of the mariadb node to produce a database dump if needed. `backup_mariadb_database.rb` uses `linode-cli` to automate most of this process:

* Get an inventory of linodes and identify the mariadb node and its backups
* Create a new node and restore to the most recent backup to it.
* Boot it in recovery mode so that `consul` doesn't disrupt the live production cloud.
* Disable the `consul` service, then boot the image normally
* Configure the node to access `/data/mariadb` via mysql/mariadb (not via a container)
* Use `mysqldump` to generate (and save on your computer) a dashboard.sql file.

### Extending the nginx config

To add a new domain to be handled by the nginx node of an up-and-running cluster:

1. Configure DNS by adding an A record for the new domain / subdomain.
2. Log in to the nginx node
3. Manually run the `for $domain in $domains` steps from `provision_agent_nginx.sh` to set up dummy certs. (Replace the variables as needed.)
4. In `nginx.hcl.tmpl`, add a new port 80 server for the new domain (you can hard-code the domain at this stage), then deploy it and confirm that the rails domain still works. (If it doesn't come back online after a short period of downtime, there may be an error in the config, so you should undo the change and re-deploy the nginx job immediately.)
5. Add the new domain to the server copy of `provision_nginx_ssl.sh` and run it, verifying that the certificate for the new domain was successfully installed.
6. Run the `renew_nginx_ssl.sh` script to make the cert live
7. Add a port 443 entry for the new domain to `nginx.hcl.tmpl`, then deploy it and confirm it works.

Once the template code is updated and working, update the codebase to incorporate the new domain automatically for new clusters:

1. Update the data flow for variables, starting from the `nginx.hcl.tpl` file and going through `linode/main.tf` to the variables and secrets files. Replace any hard-coded values with variables.
2. Update `provision_nginx_ssl.sh` to include an additional domain.
3. Update `provision_agent_nginx.sh` and its call site in the `linode/main.tf` provisioner to handle the additional argument.
4. Update the README to include DNS for the new domain.

### Upgrading nomad, consul and waypoint

On both server and clients, `nomad` is installed the Debian way and can be upgraded through `apt` (followed by restarting the service). (See also https://www.nomadproject.io/docs/upgrade)

Upgrade `nomad_server` instance first:
    1. As root on the instance, `apt update`, `apt install nomad` (or specify the version, like `nomad=1.1.6`)
    2. `systemctl restart nomadserver`

Then upgrade each client instance:
    1. As root on the instance, `apt update`, `apt install nomad` (as above)
    2. `systemctl restart nomadclient`

Upgrading `consul` is basically the same (https://www.consul.io/docs/upgrading), but you should do `consul leave` before restarting `consulserver` / `consulclient`. (This will break networking briefly.)

One way to upgrade `waypoint` is to stop the `waypoint-server` and `waypoint-runner` jobs, clear them out with `nomad system gc`, then delete the installation `null_resource` entry in the tfstate file and run `terragrunt run-all apply` to re-provision it with a fresh server.

Upgrades to `nomad` and `waypoint` upgrades do not appear to cause any service disruption, while `consul` upgrades cause brief downtime while networking is broken.

### Changing nomad configs

The provisioning scripts are normally just run at the time a resource (ie, a server) is created by Terraform, and those scripts include the nomad client.hcl configs that specify host volumes and certs for consul networking. If you need to change any of these configs, you'll need to edit the corresponding config files on the resources and then restart the `nomadclient` service. (This will not restart running job containers.)

### Shuffling jobs across nomad clients

Sometimes, jobs that could be running anywhere end up on a client that is supposed to be for specific jobs (eg, the railsweb client or the nginx client). You can get them to move to a different client via the nomad UI:

* From the Clients view, go to the client that is hosting a job it shouldn't be.
* Turn off the 'Eligible' toggle, which will prevent jobs from being placed there (but won't affect running jobs).
* Stop the misplaced job, then start it again. It should get allocated to a different client.
* Turn the 'Eligible' toggle back on. Now it's ready to run the jobs it ought to be running.

### Managing jobs

Most of the core jobs are managed through terraform and have their own `.hcl.tmpl` files. However, the waypoint-server and waypoint-runner jobs are set up once during waypoint server installation, and will only be updated if you upgrade or reinstall the waypoint server, or manually interact with the jobs. Once you source the `nomad.sh` file, you can use `nomad` locally to interact with the cluster and its job allocations. Useful commands include:

* `nomad job status` - list all the allocated jobs
* `nomad job stop waypoint-server` - kill a job
* `nomad system gc` - run the garbage collector to clear out dead jobs and clients
