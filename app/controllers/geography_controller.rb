# Options for the province → district → sub-district selects on the address step.
class GeographyController < ApplicationController
  def districts
    render json: District.where(province_id: params[:province_id]).order(:name_th).map { { id: it.id, name: it.name_th } }
  end

  def sub_districts
    render json: SubDistrict.where(district_id: params[:district_id]).order(:name_th).map { { id: it.id, name: it.name_th, postcode: it.postcode } }
  end
end
