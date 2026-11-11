# Automatic checks shown as badges on the admin review screen. Each check is
# { label:, status: :ok | :warn | :fail }.
class Onboarding::Checks
  def initialize(user)
    @user = user
    @profile = user.profile
    @bank_account = user.bank_accounts.first
  end

  def all
    [ id_checksum, duplicate_id, age, affidavit_age, bank_name, pep ].compact
  end

  private
    attr_reader :user, :profile, :bank_account

    def id_checksum
      id = user.juristic? ? profile&.tax_id : profile&.national_id
      check("เลข#{user.juristic? ? "ผู้เสียภาษี" : "บัตรประชาชน"}ถูกต้อง (checksum)", ThaiIdValidator.valid?(id))
    end

    def duplicate_id
      return unless profile

      id_column = user.juristic? ? :tax_id : :national_id
      value = profile[id_column]
      taken = value.present? && UserProfile.where(id_column => value).where.not(id: profile.id).exists?
      check("ไม่ซ้ำกับผู้ใช้อื่น", !taken)
    end

    def age
      return unless user.individual? && profile&.date_of_birth

      check("อายุ #{UserProfile::MIN_AGE} ปีขึ้นไป", profile.date_of_birth <= UserProfile::MIN_AGE.years.ago.to_date)
    end

    def affidavit_age
      return unless user.juristic? && profile&.company_affidavit_issued_on

      check("หนังสือรับรองออกไม่เกิน 6 เดือน", profile.company_affidavit_issued_on >= UserProfile::AFFIDAVIT_MAX_AGE.ago.to_date)
    end

    def bank_name
      check("ชื่อบัญชีธนาคารตรงกับชื่อในโปรไฟล์", bank_account&.name_matches_profile?, failure: :warn)
    end

    def pep
      return unless profile

      profile.is_pep ? { label: "เป็นบุคคลที่มีสถานภาพทางการเมือง (PEP) — ตรวจสอบเพิ่ม", status: :warn } : { label: "ไม่ใช่ PEP", status: :ok }
    end

    def check(label, passed, failure: :fail)
      { label: label, status: passed ? :ok : failure }
    end
end
