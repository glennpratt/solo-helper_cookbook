DESCRIPTION
===========

Includes library files to 'monkey patch' Chef with addition solo features.

REQUIREMENTS
============

 - Chef 10.0.4.rc3 or greater.
 - Data bags directory, with location configured.
   - For vagrant: chef.data_bags_path = "data_bags"

INSTALLATION
============

 - cd <path/to/cookbooks>
 - git clone https://github.com/glennpratt/solo-helper_cookbook solo-helper
 - add recipe[solo-helper] to your run list
   - For vagrant: chef.add_recipe "solo_helper"
FEATURES
========

 - Solo search
 - Ignore node saves (nothing to save it to)
 - Ignore file permissions issues (helpfull when deploying onto NFS mount)

