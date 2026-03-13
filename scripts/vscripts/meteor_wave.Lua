meteor_wave = class({})
modifier_meteor_wave_burn = class({})

function meteor_wave:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

LinkLuaModifier("modifier_meteor_wave_burn", "meteor_wave", LUA_MODIFIER_MOTION_NONE)

function meteor_wave:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	local impact_damage = 100
	local burn_damage = 50
	local burn_duration = 3.0
	local radius = 200
	local impact_delay = 0.6

	EmitSoundOnLocationWithCaster(point, "Hero_Invoker.ChaosMeteor.Cast", caster)

	local pfx = ParticleManager:CreateParticle(
	"particles/ui_mouseactions/range_finder_tower_aoe.vpcf",
	PATTACH_WORLDORIGIN,
	nil
)
ParticleManager:SetParticleControl(pfx, 0, point)
ParticleManager:SetParticleControl(pfx, 1, Vector(radius, 0, 0))
ParticleManager:ReleaseParticleIndex(pfx)

	Timers:CreateTimer(impact_delay, function()
		EmitSoundOnLocationWithCaster(point, "Hero_Invoker.ChaosMeteor.Impact", caster)

		local enemies = FindUnitsInRadius(
			caster:GetTeamNumber(),
			point,
			nil,
			radius,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			DOTA_UNIT_TARGET_FLAG_NONE,
			FIND_ANY_ORDER,
			false
		)

		for _, enemy in pairs(enemies) do
			ApplyDamage({
				victim = enemy,
				attacker = caster,
				damage = impact_damage,
				damage_type = DAMAGE_TYPE_MAGICAL,
				ability = self
			})

			enemy:AddNewModifier(caster, self, "modifier_meteor_wave_burn", {
				duration = burn_duration
			})
		end
	end)
end

function modifier_meteor_wave_burn:IsDebuff() return true end
function modifier_meteor_wave_burn:IsPurgable() return true end

function modifier_meteor_wave_burn:OnCreated()
	if not IsServer() then return end

	self.total_damage = 50
	self.duration = 3.0
	self.damage_per_tick = self.total_damage / self.duration

	self:StartIntervalThink(1.0)
end

function modifier_meteor_wave_burn:OnIntervalThink()
	if not IsServer() then return end

	ApplyDamage({
		victim = self:GetParent(),
		attacker = self:GetCaster(),
		damage = self.damage_per_tick,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self:GetAbility()
	})
end