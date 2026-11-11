# Loads Thai provinces, districts and sub-districts (with postcodes) from
# db/seeds/thai_geography.json. Safe to run again: rows are upserted by code.
module ThaiGeography
  DATA_PATH = Rails.root.join("db/seeds/thai_geography.json")

  def self.import!(path = DATA_PATH)
    provinces = JSON.parse(File.read(path)).fetch("provinces")

    Province.upsert_all(provinces.map { { code: it["code"], name_th: it["th"], name_en: it["en"] } }, unique_by: :code)
    province_ids = Province.pluck(:code, :id).to_h

    districts = provinces.flat_map { |p| p["districts"].map { it.merge("province_code" => p["code"]) } }
    District.upsert_all(districts.map { { code: it["code"], name_th: it["th"], name_en: it["en"], province_id: province_ids.fetch(it["province_code"]) } }, unique_by: :code)
    district_ids = District.pluck(:code, :id).to_h

    sub_districts = districts.flat_map { |d| d["sub_districts"].map { it.merge("district_code" => d["code"]) } }
    SubDistrict.upsert_all(sub_districts.map {
      { code: it["code"], name_th: it["th"], name_en: it["en"], postcode: it["postcode"], district_id: district_ids.fetch(it["district_code"]) }
    }, unique_by: :code)
  end
end
