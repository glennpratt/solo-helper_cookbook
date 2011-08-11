# TODO This is a monster hack.  See if we can't automatically make some
# decisions about uid/gid mapping for Vagrant.
#
# Prevent chown errors from killing a Chef run.  It's hard to make this work
# over NFS.
if Chef::Config[:solo]
  class Chef
    class Provider
      class File
        # Set the ownership on the file, assuming it is not set correctly already.
        def set_owner
          begin
            unless compare_owner
              @set_user_id = negative_complement(@set_user_id)
              ::File.chown(@set_user_id, nil, @new_resource.path)
              Chef::Log.info("#{@new_resource} owner changed to #{@set_user_id}")
              @new_resource.updated_by_last_action(true)
            end
          rescue
            Chef::Log.error("Error setting file owner.  Error consumed because it doesn't work on NFS.")
          end
        end
        def set_group
          begin
            unless compare_group
              @set_group_id = negative_complement(@set_group_id)
              ::File.chown(nil, @set_group_id, @new_resource.path)
              Chef::Log.info("#{@new_resource} group changed to #{@set_group_id}")
              @new_resource.updated_by_last_action(true)
            end
          rescue
            Chef::Log.error("Error setting file group.  Error consumed because it doesn't work on NFS.")
          end
        end
      end

      class Deploy
        def enforce_ownership
          begin
            FileUtils.chown_R(@new_resource.user, @new_resource.group, @new_resource.deploy_to)
            Chef::Log.info("#{@new_resource} set user to #{@new_resource.user}") if @new_resource.user
            Chef::Log.info("#{@new_resource} set group to #{@new_resource.group}") if @new_resource.group
          rescue
            Chef::Log.error("Error setting deployment group.  Error consumed because it doesn't work on NFS.")
          end
        end
      end
    end
  end
  
  class Chef
    class FileAccessControl
      def set_owner
        if (uid = target_uid) && (uid != stat.uid)
          begin
            File.chown(uid, nil, file)
            Chef::Log.info("#{log_string} owner changed to #{uid}")
            modified
          rescue
            Chef::Log.error("Error setting file group.  Error consumed because it doesn't work on NFS.")
          end
        end
      end
      def set_group
        if (gid = target_gid) && (gid != stat.gid)
          begin
            File.chown(nil, gid, file)
            Chef::Log.info("#{log_string} owner changed to #{gid}")
            modified
          rescue
            Chef::Log.error("Error setting file group.  Error consumed because it doesn't work on NFS.")
          end
        end
      end
    end
  end
end
