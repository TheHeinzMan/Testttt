
ENT.DSArmorBulletPenetrationType = DMG_AIRBOAT + DMG_SNIPER

function ENT:AddArmor( pos, ang, mins, maxs, health, minforce, target )
	local Armor = ents.Create( "lvs_armor" )

	if not IsValid( Armor ) then return end

	if not target then target = self end

	Armor:SetPos( target:LocalToWorld( pos ) )
	Armor:SetAngles( target:LocalToWorldAngles( ang ) )
	Armor:Spawn()
	Armor:Activate()
	Armor:SetParent( target )
	Armor:SetBase( self )
	Armor:SetMaxHP( health )
	Armor:SetHP( health )
	Armor:SetMins( mins )
	Armor:SetMaxs( maxs )

	if isnumber( minforce ) then
		Armor:SetIgnoreForce( minforce + self.DSArmorIgnoreForce )
	else
		Armor:SetIgnoreForce( self.DSArmorIgnoreForce )
	end

	self:DeleteOnRemove( Armor )

	self:TransferCPPI( Armor )

	self:AddDSArmor( {
		pos = pos,
		ang = ang,
		mins = mins,
		maxs = maxs,
		entity = target,
		Callback = function( tbl, ent, dmginfo )
			if not IsValid( Armor ) or not dmginfo:IsDamageType( self.DSArmorBulletPenetrationType + DMG_BLAST ) then return true end

			local MaxHealth = self:GetMaxHP()
			local MaxArmor = Armor:GetMaxHP()
			local Damage = dmginfo:GetDamage()

			local ArmoredHealth = MaxHealth + MaxArmor
			local NumShotsToKill = ArmoredHealth / Damage

			local ScaleDamage =  math.Clamp( MaxHealth / (NumShotsToKill * Damage),0,1)

			local DidDamage = Armor:TakeTransmittedDamage( dmginfo )

			if DidDamage then
				if dmginfo:IsDamageType( DMG_PREVENT_PHYSICS_FORCE ) then
					dmginfo:ScaleDamage( 0.05 )
				end

				local Attacker = dmginfo:GetAttacker() 
	
				if IsValid( Attacker ) and Attacker:IsPlayer() then
					local NonLethal = self:GetHP() > Damage * ScaleDamage

					if not ent._preventArmorMarker then
						net.Start( "lvs_armormarker" )
							net.WriteBool( NonLethal )
						net.Send( Attacker )

						if not NonLethal then
							ent._preventArmorMarker = true
						end
					end
				end

				dmginfo:ScaleDamage( ScaleDamage )
			else
				dmginfo:ScaleDamage( 0 )
			end

			return true
		end
	} )

	return Armor
end

function ENT:OnArmorMaintenance()
	local Repaired = false

	for _, part in pairs( self:GetCrosshairFilterEnts() ) do
		if not IsValid( part ) then continue end

		if part:GetClass() ~= "lvs_armor" then continue end

		part:OnRepaired()

		if part:GetHP() ~= part:GetMaxHP() then
			part:SetHP( part:GetMaxHP() )

			if part:GetDestroyed() then part:SetDestroyed( false ) end

			Repaired = true
		end
	end

	return Repaired
end
