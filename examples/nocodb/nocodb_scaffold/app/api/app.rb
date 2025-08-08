# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/activerecord'
require 'json'
require 'rapitapir'
require 'rapitapir/sinatra_rapitapir'
require_relative '../models_loader'

module API
  class App < RapiTapir::SinatraRapiTapir
    register Sinatra::ActiveRecordExtension
    set :database_file, File.expand_path('../../config/database.yml', __dir__)

    rapitapir do
      info(title: "nocodb", version: "2.0")
      development_defaults!
    end

    helpers do
      def json(obj)
        content_type :json
        JSON.dump(obj)
      end
    end

    # Basic health
    get '/health' do
      json(ok: true)
    end

    # Generated endpoints (scaffold level)
    endpoint(
    RapiTapir.get('/api/v2/tables/mtt03xolo8m1kve/records')
                .query(:viewId, T.optional(T.string), description: "Allows you to fetch records that are currently visible within a specific view.\n\nViews:\n* vwa6csrzocx682zu - Default view")
                .query(:fields, T.optional(T.string), description: "Array of field names or comma separated filed names to include in the response objects. In array syntax pass it like `fields[]=field1&fields[]=field2` or alternately `fields=field1,field2`.")
                .query(:sort, T.optional(T.string), description: "Comma separated field names to sort rows, rows will sort in ascending order based on provided columns. To sort in descending order provide `-` prefix along with column name, like `-field`. Example : `sort=field1,-field2`")
                .query(:where, T.optional(T.string), description: "This can be used for filtering rows, which accepts complicated where conditions. For more info visit [here](https://docs.nocodb.com/developer-resources/rest-apis#comparison-operators). Example : `where=(field1,eq,value)`")
                .query(:limit, T.optional(T.float(minimum: 1)), description: "The `limit` parameter used for pagination, the response collection size depends on limit value with default value `25` and maximum value `1000`, which can be overridden by environment variables `DB_QUERY_LIMIT_DEFAULT` and `DB_QUERY_LIMIT_MAX` respectively.")
                .query(:shuffle, T.optional(T.float(minimum: 0, maximum: 1)), description: "The `shuffle` parameter used for pagination, the response will be shuffled if it is set to 1.")
                .query(:offset, T.optional(T.float(minimum: 0)), description: "The `offset` parameter used for pagination, the value helps to select collection from a certain index.")
                .header("xc-token", T.string, description: "API token")
                .ok(T.hash({ "list" => T.optional(T.array(T.hash({ "Id" => T.optional(T.integer), "Title" => T.optional(T.string) }))), "PageInfo" => T.optional(T.hash({ "pageSize" => T.optional(T.integer), "totalRows" => T.optional(T.integer), "isFirstPage" => T.optional(T.boolean), "isLastPage" => T.optional(T.boolean), "page" => T.optional(T.float) })) }))
                .summary("Features list")
                .description("List of all rows from Features table and response data fields can be filtered based on query params.")
                .tags("Features")
            .build
) do
  Models::Feature.limit(25).all.map(&:attributes)
end


              endpoint(
    RapiTapir.post('/api/v2/tables/mtt03xolo8m1kve/records')
                .header("xc-token", T.string, description: "API token")
                .json_body(T.hash({}))
                .ok(T.hash({ "Id" => T.optional(T.integer), "Title" => T.optional(T.string) }))
                .summary("Features create")
                .description("Insert a new row in table by providing a key value pair object where key refers to the column alias. All the required fields should be included with payload excluding `autoincrement` and column with default value.")
                .tags("Features")
            .build
) do
  payload = JSON.parse(request.body.read) rescue {}
model = Models::Feature.create(payload)
model.attributes
end


              endpoint(
    RapiTapir.patch('/api/v2/tables/mtt03xolo8m1kve/records')
                .header("xc-token", T.string, description: "API token")
                .json_body(T.hash({}))
                .ok(T.hash({}))
                .summary("Features update")
                .description("Partial update row in table by providing a key value pair object where key refers to the column alias. You need to only include columns which you want to update.")
                .tags("Features")
            .build
) do
  payload = JSON.parse(request.body.read) rescue {}
model = Models::Feature.first
halt 404 unless model
model.update(payload)
model.attributes
end


              endpoint(
    RapiTapir.delete('/api/v2/tables/mtt03xolo8m1kve/records')
                .header("xc-token", T.string, description: "API token")
                .json_body(T.hash({}))
                .ok(T.hash({}))
                .summary("Features delete")
                .description("Delete a row by using the **primary key** column value.")
                .tags("Features")
            .build
) do
  model = Models::Feature.first
halt 404 unless model
model.destroy
{}
end


              endpoint(
    RapiTapir.get('/api/v2/tables/mtt03xolo8m1kve/records/:recordId')
                .path_param(:recordId, T.string, description: "Primary key of the record you want to read. If the table have composite primary key then combine them by using `___` and pass it as primary key.")
                .query(:fields, T.optional(T.string), description: "Array of field names or comma separated filed names to include in the response objects. In array syntax pass it like `fields[]=field1&fields[]=field2` or alternately `fields=field1,field2`.")
                .header("xc-token", T.string, description: "API token")
                .created(T.hash({ "Id" => T.optional(T.integer), "Title" => T.optional(T.string) }))
                .summary("Features read")
                .description("Read a row data by using the **primary key** column value.")
                .tags("Features")
            .build
) do
  rec = Models::Feature.find_by(id: params[:recordId])
halt 404 unless rec
rec.attributes
end


              endpoint(
    RapiTapir.get('/api/v2/tables/mtt03xolo8m1kve/records/count')
                .query(:viewId, T.optional(T.string), description: "Allows you to fetch records that are currently visible within a specific view.\n\nViews:\n* vwa6csrzocx682zu - Default view")
                .query(:where, T.optional(T.string), description: "This can be used for filtering rows, which accepts complicated where conditions. For more info visit [here](https://docs.nocodb.com/developer-resources/rest-apis#comparison-operators). Example : `where=(field1,eq,value)`")
                .header("xc-token", T.string, description: "API token")
                .ok(T.hash({ "count" => T.optional(T.float) }))
                .summary("Features count")
                .description("Get rows count of a table by applying optional filters.")
                .tags("Features")
            .build
) do
  Models::Feature.limit(25).all.map(&:attributes)
end


              endpoint(
    RapiTapir.get('/api/v2/tables/mk3tjsn0g0141aj/records')
                .query(:viewId, T.optional(T.string), description: "Allows you to fetch records that are currently visible within a specific view.\n\nViews:\n* vwt2z2kv3xnny2rn - Default view")
                .query(:fields, T.optional(T.string), description: "Array of field names or comma separated filed names to include in the response objects. In array syntax pass it like `fields[]=field1&fields[]=field2` or alternately `fields=field1,field2`.")
                .query(:sort, T.optional(T.string), description: "Comma separated field names to sort rows, rows will sort in ascending order based on provided columns. To sort in descending order provide `-` prefix along with column name, like `-field`. Example : `sort=field1,-field2`")
                .query(:where, T.optional(T.string), description: "This can be used for filtering rows, which accepts complicated where conditions. For more info visit [here](https://docs.nocodb.com/developer-resources/rest-apis#comparison-operators). Example : `where=(field1,eq,value)`")
                .query(:limit, T.optional(T.float(minimum: 1)), description: "The `limit` parameter used for pagination, the response collection size depends on limit value with default value `25` and maximum value `1000`, which can be overridden by environment variables `DB_QUERY_LIMIT_DEFAULT` and `DB_QUERY_LIMIT_MAX` respectively.")
                .query(:shuffle, T.optional(T.float(minimum: 0, maximum: 1)), description: "The `shuffle` parameter used for pagination, the response will be shuffled if it is set to 1.")
                .query(:offset, T.optional(T.float(minimum: 0)), description: "The `offset` parameter used for pagination, the value helps to select collection from a certain index.")
                .header("xc-token", T.string, description: "API token")
                .ok(T.hash({ "list" => T.optional(T.array(T.hash({ "Id" => T.optional(T.integer), "name" => T.optional(T.string), "type" => T.optional(T.string), "start_date" => T.optional(T.string), "end_date" => T.optional(T.string), "is_featured" => T.optional(T.boolean), "description" => T.optional(T.string), "price" => T.optional(T.string), "old_price" => T.optional(T.string), "deposit_price" => T.optional(T.float), "deposit_payment_link" => T.optional(T.string), "image" => T.optional(T.string), "gallery_images" => T.optional(T.hash({})), "label" => T.optional(T.string), "sold_out" => T.optional(T.boolean), "preview_mode" => T.optional(T.boolean), "total_distance_km" => T.optional(T.integer), "group_size_max" => T.optional(T.integer), "physical_rating" => T.optional(T.string), "start_location" => T.optional(T.string), "region" => T.optional(T.string), "accommodation" => T.optional(T.string), "transport" => T.optional(T.string), "trip_highlights" => T.optional(T.string), "stages" => T.optional(T.integer) }))), "PageInfo" => T.optional(T.hash({ "pageSize" => T.optional(T.integer), "totalRows" => T.optional(T.integer), "isFirstPage" => T.optional(T.boolean), "isLastPage" => T.optional(T.boolean), "page" => T.optional(T.float) })) }))
                .summary("Tours list")
                .description("List of all rows from Tours table and response data fields can be filtered based on query params.")
                .tags("Tours")
            .build
) do
  Models::Tour.limit(25).all.map(&:attributes)
end


              endpoint(
    RapiTapir.post('/api/v2/tables/mk3tjsn0g0141aj/records')
                .header("xc-token", T.string, description: "API token")
                .json_body(T.hash({}))
                .ok(T.hash({ "Id" => T.optional(T.integer), "name" => T.optional(T.string), "type" => T.optional(T.string), "start_date" => T.optional(T.string), "end_date" => T.optional(T.string), "is_featured" => T.optional(T.boolean), "description" => T.optional(T.string), "price" => T.optional(T.string), "old_price" => T.optional(T.string), "deposit_price" => T.optional(T.float), "deposit_payment_link" => T.optional(T.string), "image" => T.optional(T.string), "gallery_images" => T.optional(T.hash({})), "label" => T.optional(T.string), "sold_out" => T.optional(T.boolean), "preview_mode" => T.optional(T.boolean), "total_distance_km" => T.optional(T.integer), "group_size_max" => T.optional(T.integer), "physical_rating" => T.optional(T.string), "start_location" => T.optional(T.string), "region" => T.optional(T.string), "accommodation" => T.optional(T.string), "transport" => T.optional(T.string), "trip_highlights" => T.optional(T.string), "stages" => T.optional(T.integer) }))
                .summary("Tours create")
                .description("Insert a new row in table by providing a key value pair object where key refers to the column alias. All the required fields should be included with payload excluding `autoincrement` and column with default value.")
                .tags("Tours")
            .build
) do
  payload = JSON.parse(request.body.read) rescue {}
model = Models::Tour.create(payload)
model.attributes
end


              endpoint(
    RapiTapir.patch('/api/v2/tables/mk3tjsn0g0141aj/records')
                .header("xc-token", T.string, description: "API token")
                .json_body(T.hash({}))
                .ok(T.hash({}))
                .summary("Tours update")
                .description("Partial update row in table by providing a key value pair object where key refers to the column alias. You need to only include columns which you want to update.")
                .tags("Tours")
            .build
) do
  payload = JSON.parse(request.body.read) rescue {}
model = Models::Tour.first
halt 404 unless model
model.update(payload)
model.attributes
end


              endpoint(
    RapiTapir.delete('/api/v2/tables/mk3tjsn0g0141aj/records')
                .header("xc-token", T.string, description: "API token")
                .json_body(T.hash({}))
                .ok(T.hash({}))
                .summary("Tours delete")
                .description("Delete a row by using the **primary key** column value.")
                .tags("Tours")
            .build
) do
  model = Models::Tour.first
halt 404 unless model
model.destroy
{}
end


              endpoint(
    RapiTapir.get('/api/v2/tables/mk3tjsn0g0141aj/records/:recordId')
                .path_param(:recordId, T.string, description: "Primary key of the record you want to read. If the table have composite primary key then combine them by using `___` and pass it as primary key.")
                .query(:fields, T.optional(T.string), description: "Array of field names or comma separated filed names to include in the response objects. In array syntax pass it like `fields[]=field1&fields[]=field2` or alternately `fields=field1,field2`.")
                .header("xc-token", T.string, description: "API token")
                .created(T.hash({ "Id" => T.optional(T.integer), "name" => T.optional(T.string), "type" => T.optional(T.string), "start_date" => T.optional(T.string), "end_date" => T.optional(T.string), "is_featured" => T.optional(T.boolean), "description" => T.optional(T.string), "price" => T.optional(T.string), "old_price" => T.optional(T.string), "deposit_price" => T.optional(T.float), "deposit_payment_link" => T.optional(T.string), "image" => T.optional(T.string), "gallery_images" => T.optional(T.hash({})), "label" => T.optional(T.string), "sold_out" => T.optional(T.boolean), "preview_mode" => T.optional(T.boolean), "total_distance_km" => T.optional(T.integer), "group_size_max" => T.optional(T.integer), "physical_rating" => T.optional(T.string), "start_location" => T.optional(T.string), "region" => T.optional(T.string), "accommodation" => T.optional(T.string), "transport" => T.optional(T.string), "trip_highlights" => T.optional(T.string), "stages" => T.optional(T.integer) }))
                .summary("Tours read")
                .description("Read a row data by using the **primary key** column value.")
                .tags("Tours")
            .build
) do
  rec = Models::Tour.find_by(id: params[:recordId])
halt 404 unless rec
rec.attributes
end


              endpoint(
    RapiTapir.get('/api/v2/tables/mk3tjsn0g0141aj/records/count')
                .query(:viewId, T.optional(T.string), description: "Allows you to fetch records that are currently visible within a specific view.\n\nViews:\n* vwt2z2kv3xnny2rn - Default view")
                .query(:where, T.optional(T.string), description: "This can be used for filtering rows, which accepts complicated where conditions. For more info visit [here](https://docs.nocodb.com/developer-resources/rest-apis#comparison-operators). Example : `where=(field1,eq,value)`")
                .header("xc-token", T.string, description: "API token")
                .ok(T.hash({ "count" => T.optional(T.float) }))
                .summary("Tours count")
                .description("Get rows count of a table by applying optional filters.")
                .tags("Tours")
            .build
) do
  Models::Tour.limit(25).all.map(&:attributes)
end


              endpoint(
    RapiTapir.get('/api/v2/tables/mk3tjsn0g0141aj/links/:linkFieldId/records/:recordId')
                .path_param(:linkFieldId, T.string, description: "**Links Field Identifier** corresponding to the relation field `Links` established between tables.\n\nLink Columns:\n* c03xxobu37h493o - stages")
                .path_param(:recordId, T.string, description: "Primary key of the record you want to read. If the table have composite primary key then combine them by using `___` and pass it as primary key.")
                .query(:fields, T.optional(T.string), description: "Array of field names or comma separated filed names to include in the response objects. In array syntax pass it like `fields[]=field1&fields[]=field2` or alternately `fields=field1,field2`.")
                .query(:sort, T.optional(T.string), description: "Comma separated field names to sort rows, rows will sort in ascending order based on provided columns. To sort in descending order provide `-` prefix along with column name, like `-field`. Example : `sort=field1,-field2`")
                .query(:where, T.optional(T.string), description: "This can be used for filtering rows, which accepts complicated where conditions. For more info visit [here](https://docs.nocodb.com/developer-resources/rest-apis#comparison-operators). Example : `where=(field1,eq,value)`")
                .query(:limit, T.optional(T.float(minimum: 1)), description: "The `limit` parameter used for pagination, the response collection size depends on limit value with default value `25` and maximum value `1000`, which can be overridden by environment variables `DB_QUERY_LIMIT_DEFAULT` and `DB_QUERY_LIMIT_MAX` respectively.")
                .query(:offset, T.optional(T.float(minimum: 0)), description: "The `offset` parameter used for pagination, the value helps to select collection from a certain index.")
                .header("xc-token", T.string, description: "API token")
                .ok(T.hash({ "list" => T.array(T.hash({})), "pageInfo" => T.hash({ "pageSize" => T.optional(T.integer), "totalRows" => T.optional(T.integer), "isFirstPage" => T.optional(T.boolean), "isLastPage" => T.optional(T.boolean), "page" => T.optional(T.float) }) }))
                .summary("Link Records list")
                .description("This API endpoint allows you to retrieve list of linked records for a specific `Link field` and `Record ID`. The response is an array of objects containing Primary Key and its corresponding display value.")
                .tags("Tours")
            .build
) do
  rec = Models::Tour.find_by(id: params[:linkFieldId])
halt 404 unless rec
rec.attributes
end


              endpoint(
    RapiTapir.post('/api/v2/tables/mk3tjsn0g0141aj/links/:linkFieldId/records/:recordId')
                .path_param(:linkFieldId, T.string, description: "**Links Field Identifier** corresponding to the relation field `Links` established between tables.\n\nLink Columns:\n* c03xxobu37h493o - stages")
                .path_param(:recordId, T.string, description: "Primary key of the record you want to read. If the table have composite primary key then combine them by using `___` and pass it as primary key.")
                .header("xc-token", T.string, description: "API token")
                .json_body(T.hash({}))
                .ok(T.hash({}))
                .summary("Link Records")
                .description("This API endpoint allows you to link records to a specific `Link field` and `Record ID`. The request payload is an array of record-ids from the adjacent table for linking purposes. Note that any existing links, if present, will be unaffected during this operation.")
                .tags("Tours")
            .build
) do
  payload = JSON.parse(request.body.read) rescue {}
model = Models::Tour.create(payload)
model.attributes
end


              endpoint(
    RapiTapir.delete('/api/v2/tables/mk3tjsn0g0141aj/links/:linkFieldId/records/:recordId')
                .path_param(:linkFieldId, T.string, description: "**Links Field Identifier** corresponding to the relation field `Links` established between tables.\n\nLink Columns:\n* c03xxobu37h493o - stages")
                .path_param(:recordId, T.string, description: "Primary key of the record you want to read. If the table have composite primary key then combine them by using `___` and pass it as primary key.")
                .header("xc-token", T.string, description: "API token")
                .json_body(T.hash({}))
                .ok(T.hash({}))
                .summary("Unlink Records")
                .description("This API endpoint allows you to unlink records from a specific `Link field` and `Record ID`. The request payload is an array of record-ids from the adjacent table for unlinking purposes. Note that, \n- duplicated record-ids will be ignored.\n- non-existent record-ids will be ignored.")
                .tags("Tours")
            .build
) do
  model = Models::Tour.find_by(id: params[:linkFieldId])
halt 404 unless model
model.destroy
{}
end


              endpoint(
    RapiTapir.get('/api/v2/tables/mmsajq9ewj2s4ta/records')
                .query(:viewId, T.optional(T.string), description: "Allows you to fetch records that are currently visible within a specific view.\n\nViews:\n* vwndrz5ffwfgynlb - Default view")
                .query(:fields, T.optional(T.string), description: "Array of field names or comma separated filed names to include in the response objects. In array syntax pass it like `fields[]=field1&fields[]=field2` or alternately `fields=field1,field2`.")
                .query(:sort, T.optional(T.string), description: "Comma separated field names to sort rows, rows will sort in ascending order based on provided columns. To sort in descending order provide `-` prefix along with column name, like `-field`. Example : `sort=field1,-field2`")
                .query(:where, T.optional(T.string), description: "This can be used for filtering rows, which accepts complicated where conditions. For more info visit [here](https://docs.nocodb.com/developer-resources/rest-apis#comparison-operators). Example : `where=(field1,eq,value)`")
                .query(:limit, T.optional(T.float(minimum: 1)), description: "The `limit` parameter used for pagination, the response collection size depends on limit value with default value `25` and maximum value `1000`, which can be overridden by environment variables `DB_QUERY_LIMIT_DEFAULT` and `DB_QUERY_LIMIT_MAX` respectively.")
                .query(:shuffle, T.optional(T.float(minimum: 0, maximum: 1)), description: "The `shuffle` parameter used for pagination, the response will be shuffled if it is set to 1.")
                .query(:offset, T.optional(T.float(minimum: 0)), description: "The `offset` parameter used for pagination, the value helps to select collection from a certain index.")
                .header("xc-token", T.string, description: "API token")
                .ok(T.hash({ "list" => T.optional(T.array(T.hash({ "Id" => T.optional(T.integer), "route_name" => T.optional(T.string), "gpx_url" => T.optional(T.string), "scheduled_days" => T.optional(T.integer) }))), "PageInfo" => T.optional(T.hash({ "pageSize" => T.optional(T.integer), "totalRows" => T.optional(T.integer), "isFirstPage" => T.optional(T.boolean), "isLastPage" => T.optional(T.boolean), "page" => T.optional(T.float) })) }))
                .summary("Routes list")
                .description("List of all rows from Routes table and response data fields can be filtered based on query params.")
                .tags("Routes")
            .build
) do
  Models::Route.limit(25).all.map(&:attributes)
end


              endpoint(
    RapiTapir.post('/api/v2/tables/mmsajq9ewj2s4ta/records')
                .header("xc-token", T.string, description: "API token")
                .json_body(T.hash({}))
                .ok(T.hash({ "Id" => T.optional(T.integer), "route_name" => T.optional(T.string), "gpx_url" => T.optional(T.string), "scheduled_days" => T.optional(T.integer) }))
                .summary("Routes create")
                .description("Insert a new row in table by providing a key value pair object where key refers to the column alias. All the required fields should be included with payload excluding `autoincrement` and column with default value.")
                .tags("Routes")
            .build
) do
  payload = JSON.parse(request.body.read) rescue {}
model = Models::Route.create(payload)
model.attributes
end


              endpoint(
    RapiTapir.patch('/api/v2/tables/mmsajq9ewj2s4ta/records')
                .header("xc-token", T.string, description: "API token")
                .json_body(T.hash({}))
                .ok(T.hash({}))
                .summary("Routes update")
                .description("Partial update row in table by providing a key value pair object where key refers to the column alias. You need to only include columns which you want to update.")
                .tags("Routes")
            .build
) do
  payload = JSON.parse(request.body.read) rescue {}
model = Models::Route.first
halt 404 unless model
model.update(payload)
model.attributes
end


              endpoint(
    RapiTapir.delete('/api/v2/tables/mmsajq9ewj2s4ta/records')
                .header("xc-token", T.string, description: "API token")
                .json_body(T.hash({}))
                .ok(T.hash({}))
                .summary("Routes delete")
                .description("Delete a row by using the **primary key** column value.")
                .tags("Routes")
            .build
) do
  model = Models::Route.first
halt 404 unless model
model.destroy
{}
end


              endpoint(
    RapiTapir.get('/api/v2/tables/mmsajq9ewj2s4ta/records/:recordId')
                .path_param(:recordId, T.string, description: "Primary key of the record you want to read. If the table have composite primary key then combine them by using `___` and pass it as primary key.")
                .query(:fields, T.optional(T.string), description: "Array of field names or comma separated filed names to include in the response objects. In array syntax pass it like `fields[]=field1&fields[]=field2` or alternately `fields=field1,field2`.")
                .header("xc-token", T.string, description: "API token")
                .created(T.hash({ "Id" => T.optional(T.integer), "route_name" => T.optional(T.string), "gpx_url" => T.optional(T.string), "scheduled_days" => T.optional(T.integer) }))
                .summary("Routes read")
                .description("Read a row data by using the **primary key** column value.")
                .tags("Routes")
            .build
) do
  rec = Models::Route.find_by(id: params[:recordId])
halt 404 unless rec
rec.attributes
end


              endpoint(
    RapiTapir.get('/api/v2/tables/mmsajq9ewj2s4ta/records/count')
                .query(:viewId, T.optional(T.string), description: "Allows you to fetch records that are currently visible within a specific view.\n\nViews:\n* vwndrz5ffwfgynlb - Default view")
                .query(:where, T.optional(T.string), description: "This can be used for filtering rows, which accepts complicated where conditions. For more info visit [here](https://docs.nocodb.com/developer-resources/rest-apis#comparison-operators). Example : `where=(field1,eq,value)`")
                .header("xc-token", T.string, description: "API token")
                .ok(T.hash({ "count" => T.optional(T.float) }))
                .summary("Routes count")
                .description("Get rows count of a table by applying optional filters.")
                .tags("Routes")
            .build
) do
  Models::Route.limit(25).all.map(&:attributes)
end


              endpoint(
    RapiTapir.get('/api/v2/tables/mmsajq9ewj2s4ta/links/:linkFieldId/records/:recordId')
                .path_param(:linkFieldId, T.string, description: "**Links Field Identifier** corresponding to the relation field `Links` established between tables.\n\nLink Columns:\n* c671laqhnzlzs4e - scheduled_days")
                .path_param(:recordId, T.string, description: "Primary key of the record you want to read. If the table have composite primary key then combine them by using `___` and pass it as primary key.")
                .query(:fields, T.optional(T.string), description: "Array of field names or comma separated filed names to include in the response objects. In array syntax pass it like `fields[]=field1&fields[]=field2` or alternately `fields=field1,field2`.")
                .query(:sort, T.optional(T.string), description: "Comma separated field names to sort rows, rows will sort in ascending order based on provided columns. To sort in descending order provide `-` prefix along with column name, like `-field`. Example : `sort=field1,-field2`")
                .query(:where, T.optional(T.string), description: "This can be used for filtering rows, which accepts complicated where conditions. For more info visit [here](https://docs.nocodb.com/developer-resources/rest-apis#comparison-operators). Example : `where=(field1,eq,value)`")
                .query(:limit, T.optional(T.float(minimum: 1)), description: "The `limit` parameter used for pagination, the response collection size depends on limit value with default value `25` and maximum value `1000`, which can be overridden by environment variables `DB_QUERY_LIMIT_DEFAULT` and `DB_QUERY_LIMIT_MAX` respectively.")
                .query(:offset, T.optional(T.float(minimum: 0)), description: "The `offset` parameter used for pagination, the value helps to select collection from a certain index.")
                .header("xc-token", T.string, description: "API token")
                .ok(T.hash({ "list" => T.array(T.hash({})), "pageInfo" => T.hash({ "pageSize" => T.optional(T.integer), "totalRows" => T.optional(T.integer), "isFirstPage" => T.optional(T.boolean), "isLastPage" => T.optional(T.boolean), "page" => T.optional(T.float) }) }))
                .summary("Link Records list")
                .description("This API endpoint allows you to retrieve list of linked records for a specific `Link field` and `Record ID`. The response is an array of objects containing Primary Key and its corresponding display value.")
                .tags("Routes")
            .build
) do
  rec = Models::Route.find_by(id: params[:linkFieldId])
halt 404 unless rec
rec.attributes
end


              endpoint(
    RapiTapir.post('/api/v2/tables/mmsajq9ewj2s4ta/links/:linkFieldId/records/:recordId')
                .path_param(:linkFieldId, T.string, description: "**Links Field Identifier** corresponding to the relation field `Links` established between tables.\n\nLink Columns:\n* c671laqhnzlzs4e - scheduled_days")
                .path_param(:recordId, T.string, description: "Primary key of the record you want to read. If the table have composite primary key then combine them by using `___` and pass it as primary key.")
                .header("xc-token", T.string, description: "API token")
                .json_body(T.hash({}))
                .ok(T.hash({}))
                .summary("Link Records")
                .description("This API endpoint allows you to link records to a specific `Link field` and `Record ID`. The request payload is an array of record-ids from the adjacent table for linking purposes. Note that any existing links, if present, will be unaffected during this operation.")
                .tags("Routes")
            .build
) do
  payload = JSON.parse(request.body.read) rescue {}
model = Models::Route.create(payload)
model.attributes
end


              endpoint(
    RapiTapir.delete('/api/v2/tables/mmsajq9ewj2s4ta/links/:linkFieldId/records/:recordId')
                .path_param(:linkFieldId, T.string, description: "**Links Field Identifier** corresponding to the relation field `Links` established between tables.\n\nLink Columns:\n* c671laqhnzlzs4e - scheduled_days")
                .path_param(:recordId, T.string, description: "Primary key of the record you want to read. If the table have composite primary key then combine them by using `___` and pass it as primary key.")
                .header("xc-token", T.string, description: "API token")
                .json_body(T.hash({}))
                .ok(T.hash({}))
                .summary("Unlink Records")
                .description("This API endpoint allows you to unlink records from a specific `Link field` and `Record ID`. The request payload is an array of record-ids from the adjacent table for unlinking purposes. Note that, \n- duplicated record-ids will be ignored.\n- non-existent record-ids will be ignored.")
                .tags("Routes")
            .build
) do
  model = Models::Route.find_by(id: params[:linkFieldId])
halt 404 unless model
model.destroy
{}
end


              endpoint(
    RapiTapir.get('/api/v2/tables/mol2r6h3c6fsn3m/records')
                .query(:viewId, T.optional(T.string), description: "Allows you to fetch records that are currently visible within a specific view.\n\nViews:\n* vw7lp301nw9993p2 - Default view")
                .query(:fields, T.optional(T.string), description: "Array of field names or comma separated filed names to include in the response objects. In array syntax pass it like `fields[]=field1&fields[]=field2` or alternately `fields=field1,field2`.")
                .query(:sort, T.optional(T.string), description: "Comma separated field names to sort rows, rows will sort in ascending order based on provided columns. To sort in descending order provide `-` prefix along with column name, like `-field`. Example : `sort=field1,-field2`")
                .query(:where, T.optional(T.string), description: "This can be used for filtering rows, which accepts complicated where conditions. For more info visit [here](https://docs.nocodb.com/developer-resources/rest-apis#comparison-operators). Example : `where=(field1,eq,value)`")
                .query(:limit, T.optional(T.float(minimum: 1)), description: "The `limit` parameter used for pagination, the response collection size depends on limit value with default value `25` and maximum value `1000`, which can be overridden by environment variables `DB_QUERY_LIMIT_DEFAULT` and `DB_QUERY_LIMIT_MAX` respectively.")
                .query(:shuffle, T.optional(T.float(minimum: 0, maximum: 1)), description: "The `shuffle` parameter used for pagination, the response will be shuffled if it is set to 1.")
                .query(:offset, T.optional(T.float(minimum: 0)), description: "The `offset` parameter used for pagination, the value helps to select collection from a certain index.")
                .query(:nested_Tours__fields_, T.optional(T.string), description: "Array of field names or comma separated filed names to include in the in nested column `Tours` result. In array syntax pass it like `fields[]=field1&fields[]=field2.`. Example : `nested[Tours][fields]=field1,field2`")
                .query(:nested_Routes__fields_, T.optional(T.string), description: "Array of field names or comma separated filed names to include in the in nested column `Routes` result. In array syntax pass it like `fields[]=field1&fields[]=field2.`. Example : `nested[Routes][fields]=field1,field2`")
                .header("xc-token", T.string, description: "API token")
                .ok(T.hash({ "list" => T.optional(T.array(T.hash({ "Id" => T.optional(T.integer), "day_number" => T.optional(T.string), "daily_title" => T.optional(T.string), "daily_description" => T.optional(T.string), "Tours_id" => T.optional(T.integer), "Tours" => T.optional(T.hash({ "name" => T.optional(T.string), "type" => T.optional(T.string), "start_date" => T.optional(T.string), "end_date" => T.optional(T.string), "is_featured" => T.optional(T.boolean), "description" => T.optional(T.string), "price" => T.optional(T.string), "old_price" => T.optional(T.string), "deposit_price" => T.optional(T.float), "deposit_payment_link" => T.optional(T.string), "image" => T.optional(T.string), "gallery_images" => T.optional(T.hash({})), "label" => T.optional(T.string), "sold_out" => T.optional(T.boolean), "preview_mode" => T.optional(T.boolean), "total_distance_km" => T.optional(T.integer), "group_size_max" => T.optional(T.integer), "physical_rating" => T.optional(T.string), "start_location" => T.optional(T.string), "region" => T.optional(T.string), "accommodation" => T.optional(T.string), "transport" => T.optional(T.string), "trip_highlights" => T.optional(T.string) })), "Routes_id" => T.optional(T.integer), "Routes" => T.optional(T.hash({ "route_name" => T.optional(T.string), "gpx_url" => T.optional(T.string) })), "tour_id" => T.optional(T.integer), "route_id" => T.optional(T.integer) }))), "PageInfo" => T.optional(T.hash({ "pageSize" => T.optional(T.integer), "totalRows" => T.optional(T.integer), "isFirstPage" => T.optional(T.boolean), "isLastPage" => T.optional(T.boolean), "page" => T.optional(T.float) })) }))
                .summary("ItineraryDays list")
                .description("List of all rows from ItineraryDays table and response data fields can be filtered based on query params.")
                .tags("ItineraryDays")
            .build
) do
  Models::ItineraryDay.limit(25).all.map(&:attributes)
end


              endpoint(
    RapiTapir.post('/api/v2/tables/mol2r6h3c6fsn3m/records')
                .header("xc-token", T.string, description: "API token")
                .json_body(T.hash({}))
                .ok(T.hash({ "Id" => T.optional(T.integer), "day_number" => T.optional(T.string), "daily_title" => T.optional(T.string), "daily_description" => T.optional(T.string), "Tours_id" => T.optional(T.integer), "Tours" => T.optional(T.hash({ "name" => T.optional(T.string), "type" => T.optional(T.string), "start_date" => T.optional(T.string), "end_date" => T.optional(T.string), "is_featured" => T.optional(T.boolean), "description" => T.optional(T.string), "price" => T.optional(T.string), "old_price" => T.optional(T.string), "deposit_price" => T.optional(T.float), "deposit_payment_link" => T.optional(T.string), "image" => T.optional(T.string), "gallery_images" => T.optional(T.hash({})), "label" => T.optional(T.string), "sold_out" => T.optional(T.boolean), "preview_mode" => T.optional(T.boolean), "total_distance_km" => T.optional(T.integer), "group_size_max" => T.optional(T.integer), "physical_rating" => T.optional(T.string), "start_location" => T.optional(T.string), "region" => T.optional(T.string), "accommodation" => T.optional(T.string), "transport" => T.optional(T.string), "trip_highlights" => T.optional(T.string) })), "Routes_id" => T.optional(T.integer), "Routes" => T.optional(T.hash({ "route_name" => T.optional(T.string), "gpx_url" => T.optional(T.string) })), "tour_id" => T.optional(T.integer), "route_id" => T.optional(T.integer) }))
                .summary("ItineraryDays create")
                .description("Insert a new row in table by providing a key value pair object where key refers to the column alias. All the required fields should be included with payload excluding `autoincrement` and column with default value.")
                .tags("ItineraryDays")
            .build
) do
  payload = JSON.parse(request.body.read) rescue {}
model = Models::ItineraryDay.create(payload)
model.attributes
end


              endpoint(
    RapiTapir.patch('/api/v2/tables/mol2r6h3c6fsn3m/records')
                .header("xc-token", T.string, description: "API token")
                .json_body(T.hash({}))
                .ok(T.hash({}))
                .summary("ItineraryDays update")
                .description("Partial update row in table by providing a key value pair object where key refers to the column alias. You need to only include columns which you want to update.")
                .tags("ItineraryDays")
            .build
) do
  payload = JSON.parse(request.body.read) rescue {}
model = Models::ItineraryDay.first
halt 404 unless model
model.update(payload)
model.attributes
end


              endpoint(
    RapiTapir.delete('/api/v2/tables/mol2r6h3c6fsn3m/records')
                .header("xc-token", T.string, description: "API token")
                .json_body(T.hash({}))
                .ok(T.hash({}))
                .summary("ItineraryDays delete")
                .description("Delete a row by using the **primary key** column value.")
                .tags("ItineraryDays")
            .build
) do
  model = Models::ItineraryDay.first
halt 404 unless model
model.destroy
{}
end


              endpoint(
    RapiTapir.get('/api/v2/tables/mol2r6h3c6fsn3m/records/:recordId')
                .path_param(:recordId, T.string, description: "Primary key of the record you want to read. If the table have composite primary key then combine them by using `___` and pass it as primary key.")
                .query(:fields, T.optional(T.string), description: "Array of field names or comma separated filed names to include in the response objects. In array syntax pass it like `fields[]=field1&fields[]=field2` or alternately `fields=field1,field2`.")
                .header("xc-token", T.string, description: "API token")
                .created(T.hash({ "Id" => T.optional(T.integer), "day_number" => T.optional(T.string), "daily_title" => T.optional(T.string), "daily_description" => T.optional(T.string), "Tours_id" => T.optional(T.integer), "Tours" => T.optional(T.hash({ "name" => T.optional(T.string), "type" => T.optional(T.string), "start_date" => T.optional(T.string), "end_date" => T.optional(T.string), "is_featured" => T.optional(T.boolean), "description" => T.optional(T.string), "price" => T.optional(T.string), "old_price" => T.optional(T.string), "deposit_price" => T.optional(T.float), "deposit_payment_link" => T.optional(T.string), "image" => T.optional(T.string), "gallery_images" => T.optional(T.hash({})), "label" => T.optional(T.string), "sold_out" => T.optional(T.boolean), "preview_mode" => T.optional(T.boolean), "total_distance_km" => T.optional(T.integer), "group_size_max" => T.optional(T.integer), "physical_rating" => T.optional(T.string), "start_location" => T.optional(T.string), "region" => T.optional(T.string), "accommodation" => T.optional(T.string), "transport" => T.optional(T.string), "trip_highlights" => T.optional(T.string) })), "Routes_id" => T.optional(T.integer), "Routes" => T.optional(T.hash({ "route_name" => T.optional(T.string), "gpx_url" => T.optional(T.string) })), "tour_id" => T.optional(T.integer), "route_id" => T.optional(T.integer) }))
                .summary("ItineraryDays read")
                .description("Read a row data by using the **primary key** column value.")
                .tags("ItineraryDays")
            .build
) do
  rec = Models::ItineraryDay.find_by(id: params[:recordId])
halt 404 unless rec
rec.attributes
end


              endpoint(
    RapiTapir.get('/api/v2/tables/mol2r6h3c6fsn3m/records/count')
                .query(:viewId, T.optional(T.string), description: "Allows you to fetch records that are currently visible within a specific view.\n\nViews:\n* vw7lp301nw9993p2 - Default view")
                .query(:where, T.optional(T.string), description: "This can be used for filtering rows, which accepts complicated where conditions. For more info visit [here](https://docs.nocodb.com/developer-resources/rest-apis#comparison-operators). Example : `where=(field1,eq,value)`")
                .header("xc-token", T.string, description: "API token")
                .ok(T.hash({ "count" => T.optional(T.float) }))
                .summary("ItineraryDays count")
                .description("Get rows count of a table by applying optional filters.")
                .tags("ItineraryDays")
            .build
) do
  Models::ItineraryDay.limit(25).all.map(&:attributes)
end


              endpoint(
    RapiTapir.get('/api/v2/tables/mol2r6h3c6fsn3m/links/:linkFieldId/records/:recordId')
                .path_param(:linkFieldId, T.string, description: "**Links Field Identifier** corresponding to the relation field `Links` established between tables.\n\nLink Columns:\n* c0905qjoqegx40k - Tours\n* cdlxbup3s8mp8lx - Routes")
                .path_param(:recordId, T.string, description: "Primary key of the record you want to read. If the table have composite primary key then combine them by using `___` and pass it as primary key.")
                .query(:fields, T.optional(T.string), description: "Array of field names or comma separated filed names to include in the response objects. In array syntax pass it like `fields[]=field1&fields[]=field2` or alternately `fields=field1,field2`.")
                .query(:sort, T.optional(T.string), description: "Comma separated field names to sort rows, rows will sort in ascending order based on provided columns. To sort in descending order provide `-` prefix along with column name, like `-field`. Example : `sort=field1,-field2`")
                .query(:where, T.optional(T.string), description: "This can be used for filtering rows, which accepts complicated where conditions. For more info visit [here](https://docs.nocodb.com/developer-resources/rest-apis#comparison-operators). Example : `where=(field1,eq,value)`")
                .query(:limit, T.optional(T.float(minimum: 1)), description: "The `limit` parameter used for pagination, the response collection size depends on limit value with default value `25` and maximum value `1000`, which can be overridden by environment variables `DB_QUERY_LIMIT_DEFAULT` and `DB_QUERY_LIMIT_MAX` respectively.")
                .query(:offset, T.optional(T.float(minimum: 0)), description: "The `offset` parameter used for pagination, the value helps to select collection from a certain index.")
                .header("xc-token", T.string, description: "API token")
                .ok(T.hash({ "list" => T.array(T.hash({})), "pageInfo" => T.hash({ "pageSize" => T.optional(T.integer), "totalRows" => T.optional(T.integer), "isFirstPage" => T.optional(T.boolean), "isLastPage" => T.optional(T.boolean), "page" => T.optional(T.float) }) }))
                .summary("Link Records list")
                .description("This API endpoint allows you to retrieve list of linked records for a specific `Link field` and `Record ID`. The response is an array of objects containing Primary Key and its corresponding display value.")
                .tags("ItineraryDays")
            .build
) do
  rec = Models::ItineraryDay.find_by(id: params[:linkFieldId])
halt 404 unless rec
rec.attributes
end


              endpoint(
    RapiTapir.post('/api/v2/tables/mol2r6h3c6fsn3m/links/:linkFieldId/records/:recordId')
                .path_param(:linkFieldId, T.string, description: "**Links Field Identifier** corresponding to the relation field `Links` established between tables.\n\nLink Columns:\n* c0905qjoqegx40k - Tours\n* cdlxbup3s8mp8lx - Routes")
                .path_param(:recordId, T.string, description: "Primary key of the record you want to read. If the table have composite primary key then combine them by using `___` and pass it as primary key.")
                .header("xc-token", T.string, description: "API token")
                .json_body(T.hash({}))
                .ok(T.hash({}))
                .summary("Link Records")
                .description("This API endpoint allows you to link records to a specific `Link field` and `Record ID`. The request payload is an array of record-ids from the adjacent table for linking purposes. Note that any existing links, if present, will be unaffected during this operation.")
                .tags("ItineraryDays")
            .build
) do
  payload = JSON.parse(request.body.read) rescue {}
model = Models::ItineraryDay.create(payload)
model.attributes
end


              endpoint(
    RapiTapir.delete('/api/v2/tables/mol2r6h3c6fsn3m/links/:linkFieldId/records/:recordId')
                .path_param(:linkFieldId, T.string, description: "**Links Field Identifier** corresponding to the relation field `Links` established between tables.\n\nLink Columns:\n* c0905qjoqegx40k - Tours\n* cdlxbup3s8mp8lx - Routes")
                .path_param(:recordId, T.string, description: "Primary key of the record you want to read. If the table have composite primary key then combine them by using `___` and pass it as primary key.")
                .header("xc-token", T.string, description: "API token")
                .json_body(T.hash({}))
                .ok(T.hash({}))
                .summary("Unlink Records")
                .description("This API endpoint allows you to unlink records from a specific `Link field` and `Record ID`. The request payload is an array of record-ids from the adjacent table for unlinking purposes. Note that, \n- duplicated record-ids will be ignored.\n- non-existent record-ids will be ignored.")
                .tags("ItineraryDays")
            .build
) do
  model = Models::ItineraryDay.find_by(id: params[:linkFieldId])
halt 404 unless model
model.destroy
{}
end


              endpoint(
    RapiTapir.get('/api/v2/tables/mlnp4dupyi870t2/records')
                .query(:viewId, T.optional(T.string), description: "Allows you to fetch records that are currently visible within a specific view.\n\nViews:\n* vw067mss5rhbw4vx - Default view")
                .query(:fields, T.optional(T.string), description: "Array of field names or comma separated filed names to include in the response objects. In array syntax pass it like `fields[]=field1&fields[]=field2` or alternately `fields=field1,field2`.")
                .query(:sort, T.optional(T.string), description: "Comma separated field names to sort rows, rows will sort in ascending order based on provided columns. To sort in descending order provide `-` prefix along with column name, like `-field`. Example : `sort=field1,-field2`")
                .query(:where, T.optional(T.string), description: "This can be used for filtering rows, which accepts complicated where conditions. For more info visit [here](https://docs.nocodb.com/developer-resources/rest-apis#comparison-operators). Example : `where=(field1,eq,value)`")
                .query(:limit, T.optional(T.float(minimum: 1)), description: "The `limit` parameter used for pagination, the response collection size depends on limit value with default value `25` and maximum value `1000`, which can be overridden by environment variables `DB_QUERY_LIMIT_DEFAULT` and `DB_QUERY_LIMIT_MAX` respectively.")
                .query(:shuffle, T.optional(T.float(minimum: 0, maximum: 1)), description: "The `shuffle` parameter used for pagination, the response will be shuffled if it is set to 1.")
                .query(:offset, T.optional(T.float(minimum: 0)), description: "The `offset` parameter used for pagination, the value helps to select collection from a certain index.")
                .header("xc-token", T.string, description: "API token")
                .ok(T.hash({ "list" => T.optional(T.array(T.hash({ "Id" => T.optional(T.integer), "Email" => T.optional(T.string) }))), "PageInfo" => T.optional(T.hash({ "pageSize" => T.optional(T.integer), "totalRows" => T.optional(T.integer), "isFirstPage" => T.optional(T.boolean), "isLastPage" => T.optional(T.boolean), "page" => T.optional(T.float) })) }))
                .summary("Subscribers list")
                .description("List of all rows from Subscribers table and response data fields can be filtered based on query params.")
                .tags("Subscribers")
            .build
) do
  Models::Subscriber.limit(25).all.map(&:attributes)
end


              endpoint(
    RapiTapir.post('/api/v2/tables/mlnp4dupyi870t2/records')
                .header("xc-token", T.string, description: "API token")
                .json_body(T.hash({}))
                .ok(T.hash({ "Id" => T.optional(T.integer), "Email" => T.optional(T.string) }))
                .summary("Subscribers create")
                .description("Insert a new row in table by providing a key value pair object where key refers to the column alias. All the required fields should be included with payload excluding `autoincrement` and column with default value.")
                .tags("Subscribers")
            .build
) do
  payload = JSON.parse(request.body.read) rescue {}
model = Models::Subscriber.create(payload)
model.attributes
end


              endpoint(
    RapiTapir.patch('/api/v2/tables/mlnp4dupyi870t2/records')
                .header("xc-token", T.string, description: "API token")
                .json_body(T.hash({}))
                .ok(T.hash({}))
                .summary("Subscribers update")
                .description("Partial update row in table by providing a key value pair object where key refers to the column alias. You need to only include columns which you want to update.")
                .tags("Subscribers")
            .build
) do
  payload = JSON.parse(request.body.read) rescue {}
model = Models::Subscriber.first
halt 404 unless model
model.update(payload)
model.attributes
end


              endpoint(
    RapiTapir.delete('/api/v2/tables/mlnp4dupyi870t2/records')
                .header("xc-token", T.string, description: "API token")
                .json_body(T.hash({}))
                .ok(T.hash({}))
                .summary("Subscribers delete")
                .description("Delete a row by using the **primary key** column value.")
                .tags("Subscribers")
            .build
) do
  model = Models::Subscriber.first
halt 404 unless model
model.destroy
{}
end


              endpoint(
    RapiTapir.get('/api/v2/tables/mlnp4dupyi870t2/records/:recordId')
                .path_param(:recordId, T.string, description: "Primary key of the record you want to read. If the table have composite primary key then combine them by using `___` and pass it as primary key.")
                .query(:fields, T.optional(T.string), description: "Array of field names or comma separated filed names to include in the response objects. In array syntax pass it like `fields[]=field1&fields[]=field2` or alternately `fields=field1,field2`.")
                .header("xc-token", T.string, description: "API token")
                .created(T.hash({ "Id" => T.optional(T.integer), "Email" => T.optional(T.string) }))
                .summary("Subscribers read")
                .description("Read a row data by using the **primary key** column value.")
                .tags("Subscribers")
            .build
) do
  rec = Models::Subscriber.find_by(id: params[:recordId])
halt 404 unless rec
rec.attributes
end


              endpoint(
    RapiTapir.get('/api/v2/tables/mlnp4dupyi870t2/records/count')
                .query(:viewId, T.optional(T.string), description: "Allows you to fetch records that are currently visible within a specific view.\n\nViews:\n* vw067mss5rhbw4vx - Default view")
                .query(:where, T.optional(T.string), description: "This can be used for filtering rows, which accepts complicated where conditions. For more info visit [here](https://docs.nocodb.com/developer-resources/rest-apis#comparison-operators). Example : `where=(field1,eq,value)`")
                .header("xc-token", T.string, description: "API token")
                .ok(T.hash({ "count" => T.optional(T.float) }))
                .summary("Subscribers count")
                .description("Get rows count of a table by applying optional filters.")
                .tags("Subscribers")
            .build
) do
  Models::Subscriber.limit(25).all.map(&:attributes)
end


              endpoint(
    RapiTapir.get('/api/v2/tables/mmbp7kee2ouo5gx/records')
                .query(:viewId, T.optional(T.string), description: "Allows you to fetch records that are currently visible within a specific view.\n\nViews:\n* vwo0xlmw9imt7j2s - Default view")
                .query(:fields, T.optional(T.string), description: "Array of field names or comma separated filed names to include in the response objects. In array syntax pass it like `fields[]=field1&fields[]=field2` or alternately `fields=field1,field2`.")
                .query(:sort, T.optional(T.string), description: "Comma separated field names to sort rows, rows will sort in ascending order based on provided columns. To sort in descending order provide `-` prefix along with column name, like `-field`. Example : `sort=field1,-field2`")
                .query(:where, T.optional(T.string), description: "This can be used for filtering rows, which accepts complicated where conditions. For more info visit [here](https://docs.nocodb.com/developer-resources/rest-apis#comparison-operators). Example : `where=(field1,eq,value)`")
                .query(:limit, T.optional(T.float(minimum: 1)), description: "The `limit` parameter used for pagination, the response collection size depends on limit value with default value `25` and maximum value `1000`, which can be overridden by environment variables `DB_QUERY_LIMIT_DEFAULT` and `DB_QUERY_LIMIT_MAX` respectively.")
                .query(:shuffle, T.optional(T.float(minimum: 0, maximum: 1)), description: "The `shuffle` parameter used for pagination, the response will be shuffled if it is set to 1.")
                .query(:offset, T.optional(T.float(minimum: 0)), description: "The `offset` parameter used for pagination, the value helps to select collection from a certain index.")
                .header("xc-token", T.string, description: "API token")
                .ok(T.hash({ "list" => T.optional(T.array(T.hash({ "Id" => T.optional(T.integer), "template_name" => T.optional(T.string), "subject" => T.optional(T.string), "body" => T.optional(T.string) }))), "PageInfo" => T.optional(T.hash({ "pageSize" => T.optional(T.integer), "totalRows" => T.optional(T.integer), "isFirstPage" => T.optional(T.boolean), "isLastPage" => T.optional(T.boolean), "page" => T.optional(T.float) })) }))
                .summary("Email_Templates list")
                .description("List of all rows from Email_Templates table and response data fields can be filtered based on query params.")
                .tags("Email_Templates")
            .build
) do
  Models::EmailTemplate.limit(25).all.map(&:attributes)
end


              endpoint(
    RapiTapir.post('/api/v2/tables/mmbp7kee2ouo5gx/records')
                .header("xc-token", T.string, description: "API token")
                .json_body(T.hash({}))
                .ok(T.hash({ "Id" => T.optional(T.integer), "template_name" => T.optional(T.string), "subject" => T.optional(T.string), "body" => T.optional(T.string) }))
                .summary("Email_Templates create")
                .description("Insert a new row in table by providing a key value pair object where key refers to the column alias. All the required fields should be included with payload excluding `autoincrement` and column with default value.")
                .tags("Email_Templates")
            .build
) do
  payload = JSON.parse(request.body.read) rescue {}
model = Models::EmailTemplate.create(payload)
model.attributes
end


              endpoint(
    RapiTapir.patch('/api/v2/tables/mmbp7kee2ouo5gx/records')
                .header("xc-token", T.string, description: "API token")
                .json_body(T.hash({}))
                .ok(T.hash({}))
                .summary("Email_Templates update")
                .description("Partial update row in table by providing a key value pair object where key refers to the column alias. You need to only include columns which you want to update.")
                .tags("Email_Templates")
            .build
) do
  payload = JSON.parse(request.body.read) rescue {}
model = Models::EmailTemplate.first
halt 404 unless model
model.update(payload)
model.attributes
end


              endpoint(
    RapiTapir.delete('/api/v2/tables/mmbp7kee2ouo5gx/records')
                .header("xc-token", T.string, description: "API token")
                .json_body(T.hash({}))
                .ok(T.hash({}))
                .summary("Email_Templates delete")
                .description("Delete a row by using the **primary key** column value.")
                .tags("Email_Templates")
            .build
) do
  model = Models::EmailTemplate.first
halt 404 unless model
model.destroy
{}
end


              endpoint(
    RapiTapir.get('/api/v2/tables/mmbp7kee2ouo5gx/records/:recordId')
                .path_param(:recordId, T.string, description: "Primary key of the record you want to read. If the table have composite primary key then combine them by using `___` and pass it as primary key.")
                .query(:fields, T.optional(T.string), description: "Array of field names or comma separated filed names to include in the response objects. In array syntax pass it like `fields[]=field1&fields[]=field2` or alternately `fields=field1,field2`.")
                .header("xc-token", T.string, description: "API token")
                .created(T.hash({ "Id" => T.optional(T.integer), "template_name" => T.optional(T.string), "subject" => T.optional(T.string), "body" => T.optional(T.string) }))
                .summary("Email_Templates read")
                .description("Read a row data by using the **primary key** column value.")
                .tags("Email_Templates")
            .build
) do
  rec = Models::EmailTemplate.find_by(id: params[:recordId])
halt 404 unless rec
rec.attributes
end


              endpoint(
    RapiTapir.get('/api/v2/tables/mmbp7kee2ouo5gx/records/count')
                .query(:viewId, T.optional(T.string), description: "Allows you to fetch records that are currently visible within a specific view.\n\nViews:\n* vwo0xlmw9imt7j2s - Default view")
                .query(:where, T.optional(T.string), description: "This can be used for filtering rows, which accepts complicated where conditions. For more info visit [here](https://docs.nocodb.com/developer-resources/rest-apis#comparison-operators). Example : `where=(field1,eq,value)`")
                .header("xc-token", T.string, description: "API token")
                .ok(T.hash({ "count" => T.optional(T.float) }))
                .summary("Email_Templates count")
                .description("Get rows count of a table by applying optional filters.")
                .tags("Email_Templates")
            .build
) do
  Models::EmailTemplate.limit(25).all.map(&:attributes)
end


              endpoint(
    RapiTapir.get('/api/v2/tables/md5i3700qogsqku/records')
                .query(:viewId, T.optional(T.string), description: "Allows you to fetch records that are currently visible within a specific view.\n\nViews:\n* vw124o3vdimghkq6 - Default view")
                .query(:fields, T.optional(T.string), description: "Array of field names or comma separated filed names to include in the response objects. In array syntax pass it like `fields[]=field1&fields[]=field2` or alternately `fields=field1,field2`.")
                .query(:sort, T.optional(T.string), description: "Comma separated field names to sort rows, rows will sort in ascending order based on provided columns. To sort in descending order provide `-` prefix along with column name, like `-field`. Example : `sort=field1,-field2`")
                .query(:where, T.optional(T.string), description: "This can be used for filtering rows, which accepts complicated where conditions. For more info visit [here](https://docs.nocodb.com/developer-resources/rest-apis#comparison-operators). Example : `where=(field1,eq,value)`")
                .query(:limit, T.optional(T.float(minimum: 1)), description: "The `limit` parameter used for pagination, the response collection size depends on limit value with default value `25` and maximum value `1000`, which can be overridden by environment variables `DB_QUERY_LIMIT_DEFAULT` and `DB_QUERY_LIMIT_MAX` respectively.")
                .query(:shuffle, T.optional(T.float(minimum: 0, maximum: 1)), description: "The `shuffle` parameter used for pagination, the response will be shuffled if it is set to 1.")
                .query(:offset, T.optional(T.float(minimum: 0)), description: "The `offset` parameter used for pagination, the value helps to select collection from a certain index.")
                .header("xc-token", T.string, description: "API token")
                .ok(T.hash({ "list" => T.optional(T.array(T.hash({ "Id" => T.optional(T.integer), "category" => T.optional(T.string), "question_en" => T.optional(T.string), "answer_en" => T.optional(T.string) }))), "PageInfo" => T.optional(T.hash({ "pageSize" => T.optional(T.integer), "totalRows" => T.optional(T.integer), "isFirstPage" => T.optional(T.boolean), "isLastPage" => T.optional(T.boolean), "page" => T.optional(T.float) })) }))
                .summary("Faqs list")
                .description("List of all rows from Faqs table and response data fields can be filtered based on query params.")
                .tags("Faqs")
            .build
) do
  Models::Faq.limit(25).all.map(&:attributes)
end


              endpoint(
    RapiTapir.post('/api/v2/tables/md5i3700qogsqku/records')
                .header("xc-token", T.string, description: "API token")
                .json_body(T.hash({}))
                .ok(T.hash({ "Id" => T.optional(T.integer), "category" => T.optional(T.string), "question_en" => T.optional(T.string), "answer_en" => T.optional(T.string) }))
                .summary("Faqs create")
                .description("Insert a new row in table by providing a key value pair object where key refers to the column alias. All the required fields should be included with payload excluding `autoincrement` and column with default value.")
                .tags("Faqs")
            .build
) do
  payload = JSON.parse(request.body.read) rescue {}
model = Models::Faq.create(payload)
model.attributes
end


              endpoint(
    RapiTapir.patch('/api/v2/tables/md5i3700qogsqku/records')
                .header("xc-token", T.string, description: "API token")
                .json_body(T.hash({}))
                .ok(T.hash({}))
                .summary("Faqs update")
                .description("Partial update row in table by providing a key value pair object where key refers to the column alias. You need to only include columns which you want to update.")
                .tags("Faqs")
            .build
) do
  payload = JSON.parse(request.body.read) rescue {}
model = Models::Faq.first
halt 404 unless model
model.update(payload)
model.attributes
end


              endpoint(
    RapiTapir.delete('/api/v2/tables/md5i3700qogsqku/records')
                .header("xc-token", T.string, description: "API token")
                .json_body(T.hash({}))
                .ok(T.hash({}))
                .summary("Faqs delete")
                .description("Delete a row by using the **primary key** column value.")
                .tags("Faqs")
            .build
) do
  model = Models::Faq.first
halt 404 unless model
model.destroy
{}
end


              endpoint(
    RapiTapir.get('/api/v2/tables/md5i3700qogsqku/records/:recordId')
                .path_param(:recordId, T.string, description: "Primary key of the record you want to read. If the table have composite primary key then combine them by using `___` and pass it as primary key.")
                .query(:fields, T.optional(T.string), description: "Array of field names or comma separated filed names to include in the response objects. In array syntax pass it like `fields[]=field1&fields[]=field2` or alternately `fields=field1,field2`.")
                .header("xc-token", T.string, description: "API token")
                .created(T.hash({ "Id" => T.optional(T.integer), "category" => T.optional(T.string), "question_en" => T.optional(T.string), "answer_en" => T.optional(T.string) }))
                .summary("Faqs read")
                .description("Read a row data by using the **primary key** column value.")
                .tags("Faqs")
            .build
) do
  rec = Models::Faq.find_by(id: params[:recordId])
halt 404 unless rec
rec.attributes
end


              endpoint(
    RapiTapir.get('/api/v2/tables/md5i3700qogsqku/records/count')
                .query(:viewId, T.optional(T.string), description: "Allows you to fetch records that are currently visible within a specific view.\n\nViews:\n* vw124o3vdimghkq6 - Default view")
                .query(:where, T.optional(T.string), description: "This can be used for filtering rows, which accepts complicated where conditions. For more info visit [here](https://docs.nocodb.com/developer-resources/rest-apis#comparison-operators). Example : `where=(field1,eq,value)`")
                .header("xc-token", T.string, description: "API token")
                .ok(T.hash({ "count" => T.optional(T.float) }))
                .summary("Faqs count")
                .description("Get rows count of a table by applying optional filters.")
                .tags("Faqs")
            .build
) do
  Models::Faq.limit(25).all.map(&:attributes)
end


              endpoint(
    RapiTapir.get('/api/v2/tables/mngmhudvx0kayn6/records')
                .query(:viewId, T.optional(T.string), description: "Allows you to fetch records that are currently visible within a specific view.\n\nViews:\n* vwb8brs3v286oizx - Default view")
                .query(:fields, T.optional(T.string), description: "Array of field names or comma separated filed names to include in the response objects. In array syntax pass it like `fields[]=field1&fields[]=field2` or alternately `fields=field1,field2`.")
                .query(:sort, T.optional(T.string), description: "Comma separated field names to sort rows, rows will sort in ascending order based on provided columns. To sort in descending order provide `-` prefix along with column name, like `-field`. Example : `sort=field1,-field2`")
                .query(:where, T.optional(T.string), description: "This can be used for filtering rows, which accepts complicated where conditions. For more info visit [here](https://docs.nocodb.com/developer-resources/rest-apis#comparison-operators). Example : `where=(field1,eq,value)`")
                .query(:limit, T.optional(T.float(minimum: 1)), description: "The `limit` parameter used for pagination, the response collection size depends on limit value with default value `25` and maximum value `1000`, which can be overridden by environment variables `DB_QUERY_LIMIT_DEFAULT` and `DB_QUERY_LIMIT_MAX` respectively.")
                .query(:shuffle, T.optional(T.float(minimum: 0, maximum: 1)), description: "The `shuffle` parameter used for pagination, the response will be shuffled if it is set to 1.")
                .query(:offset, T.optional(T.float(minimum: 0)), description: "The `offset` parameter used for pagination, the value helps to select collection from a certain index.")
                .header("xc-token", T.string, description: "API token")
                .ok(T.hash({ "list" => T.optional(T.array(T.hash({ "Id" => T.optional(T.integer), "Email" => T.optional(T.string), "Event" => T.optional(T.string), "Amount" => T.optional(T.string), "Tour_Id" => T.optional(T.string), "Phone_Number" => T.optional(T.string) }))), "PageInfo" => T.optional(T.hash({ "pageSize" => T.optional(T.integer), "totalRows" => T.optional(T.integer), "isFirstPage" => T.optional(T.boolean), "isLastPage" => T.optional(T.boolean), "page" => T.optional(T.float) })) }))
                .summary("Webhook list")
                .description("List of all rows from Webhook table and response data fields can be filtered based on query params.")
                .tags("Webhook")
            .build
) do
  Models::Webhook.limit(25).all.map(&:attributes)
end


              endpoint(
    RapiTapir.post('/api/v2/tables/mngmhudvx0kayn6/records')
                .header("xc-token", T.string, description: "API token")
                .json_body(T.hash({}))
                .ok(T.hash({ "Id" => T.optional(T.integer), "Email" => T.optional(T.string), "Event" => T.optional(T.string), "Amount" => T.optional(T.string), "Tour_Id" => T.optional(T.string), "Phone_Number" => T.optional(T.string) }))
                .summary("Webhook create")
                .description("Insert a new row in table by providing a key value pair object where key refers to the column alias. All the required fields should be included with payload excluding `autoincrement` and column with default value.")
                .tags("Webhook")
            .build
) do
  payload = JSON.parse(request.body.read) rescue {}
model = Models::Webhook.create(payload)
model.attributes
end


              endpoint(
    RapiTapir.patch('/api/v2/tables/mngmhudvx0kayn6/records')
                .header("xc-token", T.string, description: "API token")
                .json_body(T.hash({}))
                .ok(T.hash({}))
                .summary("Webhook update")
                .description("Partial update row in table by providing a key value pair object where key refers to the column alias. You need to only include columns which you want to update.")
                .tags("Webhook")
            .build
) do
  payload = JSON.parse(request.body.read) rescue {}
model = Models::Webhook.first
halt 404 unless model
model.update(payload)
model.attributes
end


              endpoint(
    RapiTapir.delete('/api/v2/tables/mngmhudvx0kayn6/records')
                .header("xc-token", T.string, description: "API token")
                .json_body(T.hash({}))
                .ok(T.hash({}))
                .summary("Webhook delete")
                .description("Delete a row by using the **primary key** column value.")
                .tags("Webhook")
            .build
) do
  model = Models::Webhook.first
halt 404 unless model
model.destroy
{}
end


              endpoint(
    RapiTapir.get('/api/v2/tables/mngmhudvx0kayn6/records/:recordId')
                .path_param(:recordId, T.string, description: "Primary key of the record you want to read. If the table have composite primary key then combine them by using `___` and pass it as primary key.")
                .query(:fields, T.optional(T.string), description: "Array of field names or comma separated filed names to include in the response objects. In array syntax pass it like `fields[]=field1&fields[]=field2` or alternately `fields=field1,field2`.")
                .header("xc-token", T.string, description: "API token")
                .created(T.hash({ "Id" => T.optional(T.integer), "Email" => T.optional(T.string), "Event" => T.optional(T.string), "Amount" => T.optional(T.string), "Tour_Id" => T.optional(T.string), "Phone_Number" => T.optional(T.string) }))
                .summary("Webhook read")
                .description("Read a row data by using the **primary key** column value.")
                .tags("Webhook")
            .build
) do
  rec = Models::Webhook.find_by(id: params[:recordId])
halt 404 unless rec
rec.attributes
end


              endpoint(
    RapiTapir.get('/api/v2/tables/mngmhudvx0kayn6/records/count')
                .query(:viewId, T.optional(T.string), description: "Allows you to fetch records that are currently visible within a specific view.\n\nViews:\n* vwb8brs3v286oizx - Default view")
                .query(:where, T.optional(T.string), description: "This can be used for filtering rows, which accepts complicated where conditions. For more info visit [here](https://docs.nocodb.com/developer-resources/rest-apis#comparison-operators). Example : `where=(field1,eq,value)`")
                .header("xc-token", T.string, description: "API token")
                .ok(T.hash({ "count" => T.optional(T.float) }))
                .summary("Webhook count")
                .description("Get rows count of a table by applying optional filters.")
                .tags("Webhook")
            .build
) do
  Models::Webhook.limit(25).all.map(&:attributes)
end


              endpoint(
    RapiTapir.get('/api/v2/tables/mopr1au7ctkqxmc/records')
                .query(:viewId, T.optional(T.string), description: "Allows you to fetch records that are currently visible within a specific view.\n\nViews:\n* vweo44ubz0sssudn - Default view")
                .query(:fields, T.optional(T.string), description: "Array of field names or comma separated filed names to include in the response objects. In array syntax pass it like `fields[]=field1&fields[]=field2` or alternately `fields=field1,field2`.")
                .query(:sort, T.optional(T.string), description: "Comma separated field names to sort rows, rows will sort in ascending order based on provided columns. To sort in descending order provide `-` prefix along with column name, like `-field`. Example : `sort=field1,-field2`")
                .query(:where, T.optional(T.string), description: "This can be used for filtering rows, which accepts complicated where conditions. For more info visit [here](https://docs.nocodb.com/developer-resources/rest-apis#comparison-operators). Example : `where=(field1,eq,value)`")
                .query(:limit, T.optional(T.float(minimum: 1)), description: "The `limit` parameter used for pagination, the response collection size depends on limit value with default value `25` and maximum value `1000`, which can be overridden by environment variables `DB_QUERY_LIMIT_DEFAULT` and `DB_QUERY_LIMIT_MAX` respectively.")
                .query(:shuffle, T.optional(T.float(minimum: 0, maximum: 1)), description: "The `shuffle` parameter used for pagination, the response will be shuffled if it is set to 1.")
                .query(:offset, T.optional(T.float(minimum: 0)), description: "The `offset` parameter used for pagination, the value helps to select collection from a certain index.")
                .header("xc-token", T.string, description: "API token")
                .ok(T.hash({ "list" => T.optional(T.array(T.hash({ "Id" => T.optional(T.integer), "title" => T.optional(T.string), "description" => T.optional(T.string), "content" => T.optional(T.string), "json" => T.optional(T.hash({})) }))), "PageInfo" => T.optional(T.hash({ "pageSize" => T.optional(T.integer), "totalRows" => T.optional(T.integer), "isFirstPage" => T.optional(T.boolean), "isLastPage" => T.optional(T.boolean), "page" => T.optional(T.float) })) }))
                .summary("Ideas list")
                .description("List of all rows from Ideas table and response data fields can be filtered based on query params.")
                .tags("Ideas")
            .build
) do
  Models::Idea.limit(25).all.map(&:attributes)
end


              endpoint(
    RapiTapir.post('/api/v2/tables/mopr1au7ctkqxmc/records')
                .header("xc-token", T.string, description: "API token")
                .json_body(T.hash({}))
                .ok(T.hash({ "Id" => T.optional(T.integer), "title" => T.optional(T.string), "description" => T.optional(T.string), "content" => T.optional(T.string), "json" => T.optional(T.hash({})) }))
                .summary("Ideas create")
                .description("Insert a new row in table by providing a key value pair object where key refers to the column alias. All the required fields should be included with payload excluding `autoincrement` and column with default value.")
                .tags("Ideas")
            .build
) do
  payload = JSON.parse(request.body.read) rescue {}
model = Models::Idea.create(payload)
model.attributes
end


              endpoint(
    RapiTapir.patch('/api/v2/tables/mopr1au7ctkqxmc/records')
                .header("xc-token", T.string, description: "API token")
                .json_body(T.hash({}))
                .ok(T.hash({}))
                .summary("Ideas update")
                .description("Partial update row in table by providing a key value pair object where key refers to the column alias. You need to only include columns which you want to update.")
                .tags("Ideas")
            .build
) do
  payload = JSON.parse(request.body.read) rescue {}
model = Models::Idea.first
halt 404 unless model
model.update(payload)
model.attributes
end


              endpoint(
    RapiTapir.delete('/api/v2/tables/mopr1au7ctkqxmc/records')
                .header("xc-token", T.string, description: "API token")
                .json_body(T.hash({}))
                .ok(T.hash({}))
                .summary("Ideas delete")
                .description("Delete a row by using the **primary key** column value.")
                .tags("Ideas")
            .build
) do
  model = Models::Idea.first
halt 404 unless model
model.destroy
{}
end


              endpoint(
    RapiTapir.get('/api/v2/tables/mopr1au7ctkqxmc/records/:recordId')
                .path_param(:recordId, T.string, description: "Primary key of the record you want to read. If the table have composite primary key then combine them by using `___` and pass it as primary key.")
                .query(:fields, T.optional(T.string), description: "Array of field names or comma separated filed names to include in the response objects. In array syntax pass it like `fields[]=field1&fields[]=field2` or alternately `fields=field1,field2`.")
                .header("xc-token", T.string, description: "API token")
                .created(T.hash({ "Id" => T.optional(T.integer), "title" => T.optional(T.string), "description" => T.optional(T.string), "content" => T.optional(T.string), "json" => T.optional(T.hash({})) }))
                .summary("Ideas read")
                .description("Read a row data by using the **primary key** column value.")
                .tags("Ideas")
            .build
) do
  rec = Models::Idea.find_by(id: params[:recordId])
halt 404 unless rec
rec.attributes
end


              endpoint(
    RapiTapir.get('/api/v2/tables/mopr1au7ctkqxmc/records/count')
                .query(:viewId, T.optional(T.string), description: "Allows you to fetch records that are currently visible within a specific view.\n\nViews:\n* vweo44ubz0sssudn - Default view")
                .query(:where, T.optional(T.string), description: "This can be used for filtering rows, which accepts complicated where conditions. For more info visit [here](https://docs.nocodb.com/developer-resources/rest-apis#comparison-operators). Example : `where=(field1,eq,value)`")
                .header("xc-token", T.string, description: "API token")
                .ok(T.hash({ "count" => T.optional(T.float) }))
                .summary("Ideas count")
                .description("Get rows count of a table by applying optional filters.")
                .tags("Ideas")
            .build
) do
  Models::Idea.limit(25).all.map(&:attributes)
end

  end
end
