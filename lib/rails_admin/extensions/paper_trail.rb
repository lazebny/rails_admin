require 'rails_admin/extensions/paper_trail/auditing_adapter'
require 'rails_admin/extensions/paper_trail/version_proxy'

RailsAdmin.add_extension(:paper_trail, RailsAdmin::Extensions::PaperTrail, auditing: true)
