--create a view to allow users to see details about the Physical Inventory before they approve it
CREATE VIEW chuboe_inventory_approval_v AS
 SELECT i.m_inventory_id,
    i.ad_client_id,
    i.ad_org_id,
    i.isactive,
    i.created,
    i.createdby,
    i.updated,
    i.updatedby,
    i.documentno,
    i.description,
    i.m_warehouse_id,
    i.movementdate,
    i.posted,
    i.processed,
    i.processing,
    i.updateqty,
    i.generatelist,
    i.m_perpetualinv_id,
    i.ad_orgtrx_id,
    i.c_project_id,
    i.c_campaign_id,
    i.c_activity_id,
    i.user1_id,
    i.user2_id,
    i.isapproved,
    i.docstatus,
    i.docaction,
    i.approvalamt,
    i.c_doctype_id,
    i.reversal_id,
    i.processedon,
    i.m_inventory_uu,
    i.costingmethod,
    i.chuboe_approve_text,
    i.chuboe_isapproved,
    ( SELECT count(*) AS count
           FROM m_inventoryline il
          WHERE (il.m_inventory_id = i.m_inventory_id)) AS linecount,
    i.m_inventory_id AS chuboe_inventory_approval_v_id
   FROM m_inventory i
  WHERE ((i.chuboe_isapproved = 'N'::bpchar) AND (i.docstatus = 'IP'::bpchar));