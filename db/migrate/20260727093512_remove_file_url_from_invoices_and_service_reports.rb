class RemoveFileUrlFromInvoicesAndServiceReports < ActiveRecord::Migration[8.1]
  def change
    remove_column :invoices, :file_url
    remove_column :service_reports, :file_url
  end
end
