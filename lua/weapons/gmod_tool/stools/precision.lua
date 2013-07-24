
TOOL.Category		= "Constraints"
TOOL.Name			= "#Precision"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar[ "mode" ]	 	= "1"
TOOL.ClientConVar[ "user" ] 		= "1"

TOOL.ClientConVar[ "forcelimit" ]	= "0"
TOOL.ClientConVar[ "freeze" ]	 	= "1"
TOOL.ClientConVar[ "nocollide" ]	= "1"
TOOL.ClientConVar[ "nocollideall" ]	= "0"
TOOL.ClientConVar[ "rotation" ] 	= "15"
TOOL.ClientConVar[ "rotate" ] 		= "1"
TOOL.ClientConVar[ "offset" ]	 	= "0"
TOOL.ClientConVar[ "torquelimit" ] 	= "0"
TOOL.ClientConVar[ "friction" ]	 	= "0"
TOOL.ClientConVar[ "width" ]	 	= "1"
TOOL.ClientConVar[ "offsetpercent" ] 	= "1"
TOOL.ClientConVar[ "removal" ]	 	= "0"
TOOL.ClientConVar[ "move" ]	 	= "1"
TOOL.ClientConVar[ "physdisable" ]	= "0"
TOOL.ClientConVar[ "ShadowDisable" ]	= "0"
TOOL.ClientConVar[ "allowphysgun" ]	= "0"
TOOL.ClientConVar[ "autorotate" ]	= "0"
TOOL.ClientConVar[ "entirecontrap" ]	= "0"
TOOL.ClientConVar[ "nudge" ]		= "25"
TOOL.ClientConVar[ "nudgepercent" ]	= "1"
TOOL.ClientConVar[ "disablesliderfix" ]	= "0"

//adv ballsocket
TOOL.ClientConVar[ "XRotMin" ]		= "-180"
TOOL.ClientConVar[ "XRotMax" ]		= "180"
TOOL.ClientConVar[ "YRotMin" ]		= "-180"
TOOL.ClientConVar[ "YRotMax" ]		= "180"
TOOL.ClientConVar[ "ZRotMin" ]		= "-180"
TOOL.ClientConVar[ "ZRotMax" ]		= "180"
TOOL.ClientConVar[ "XRotFric" ]		= "0"
TOOL.ClientConVar[ "YRotFric" ]		= "0"
TOOL.ClientConVar[ "ZRotFric" ]		= "0"
TOOL.ClientConVar[ "FreeMov" ]		= "0"


TOOL.ClientConVar[ "enablefeedback" ]	= "1"
TOOL.ClientConVar[ "chatfeedback" ]	= "1"
TOOL.ClientConVar[ "nudgeundo" ]	= "0"
TOOL.ClientConVar[ "moveundo" ]		= "1"
TOOL.ClientConVar[ "rotateundo" ]	= "1"


TOOL.inuse = nil
TOOL.axis = 0
TOOL.axisY = 0
TOOL.axisZ = 0
TOOL.realdegrees = 0
TOOL.lastdegrees = 0
TOOL.realdegreesY = 0
TOOL.lastdegreesY = 0
TOOL.realdegreesZ = 0
TOOL.lastdegreesZ = 0
TOOL.OldPos = 0
TOOL.axis2 = 0
TOOL.axisY2 = 0
TOOL.axisZ2 = 0
TOOL.realdegrees2 = 0
TOOL.lastdegrees2 = 0
TOOL.realdegrees2Y = 0
TOOL.lastdegrees2Y = 0
TOOL.realdegrees2Z = 0
TOOL.lastdegrees2Z = 0
TOOL.OldPos2 = 0
TOOL.SavedPos = Vector(0,0,1)

function TOOL:DoParent( Ent1, Ent2 )
	local TempEnt = Ent2
	if !(Ent1 && Ent1:IsValid() && Ent1:EntIndex() != 0) then
		self:SendMessage( "Oops, First Target was world or somthing invalid" )
		return
	end
	if !(Ent2 && Ent2:IsValid() && Ent2:EntIndex() != 0) then
		self:SendMessage( "Oops, Second Target was world or somthing invalid" )
		return
	end
	if ( Ent1 == Ent2 ) then
		self:SendMessage( "Oops, Can't parent somthing to itself" )
		return
	end
	Ent1:SetMoveType(MOVETYPE_NONE)
	local disablephysgun = self:GetClientNumber( "allowphysgun" ) == 0
	Ent1.PhysgunDisabled = disablephysgun
	Ent1:SetUnFreezable( disablephysgun )
	local Phys1 = Ent1:GetPhysicsObject()
	if Phys1:IsValid() then
		Phys1:EnableCollisions( false )
	end
	while true do
		if ( !TempEnt:GetParent():IsValid() ) then
			Ent1:SetParent( Ent2 )
			if self:GetClientNumber( "entirecontrap" ) == 0 then self:SendMessage( "Parent Set." ) end
			Phys1:Wake()
			break
		elseif ( TempEnt:GetParent() == Ent1 ) then
			UndoParent( TempEnt )
			timer.Simple( 0.1, function()//delay to stop crash
				Ent1.SetParent( Ent1, Ent2)
			end)
			self:SendMessage( "Oops, Closed Parent Loop Detected; Broken loop and set parent." )
			break
		else
			TempEnt = TempEnt:GetParent()
		end
	end
	Phys1:Wake()
	//Phys1:UpdateShadow(Ent1:GetAngles(),Ent1:GetAngles())
end

function TOOL:UndoParent( Ent1 )
	Ent1:SetParent( nil )
	Ent1:SetMoveType(MOVETYPE_VPHYSICS)
	Ent1.PhysgunDisabled = false
	Ent1:SetUnFreezable( false )
	local Phys1 = Ent1:GetPhysicsObject()
	if Phys1:IsValid() then
		Phys1:EnableCollisions( true )
		Phys1:Wake()
		//Phys1:UpdateShadow(Ent1:GetAngles(),Ent1:GetAngles())
	end
end

function TOOL:DoConstraint()

	// Get information we're about to use
	local Ent1,  Ent2  = self:GetEnt(1),    self:GetEnt(2)

	if ( !Ent1:IsValid() || CLIENT ) then
		self:ClearObjects()
		return false
	end
	// Get client's CVars
	local mode		= self:GetClientNumber( "mode", 1 )
	local forcelimit 	= self:GetClientNumber( "forcelimit", 0 )
	local freeze		= util.tobool( self:GetClientNumber( "freeze", 1 ) )
	local nocollide		= self:GetClientNumber( "nocollide", 0 )
	local nocollideall	= util.tobool( self:GetClientNumber( "nocollideall", 0 ) )
	local torquelimit	= self:GetClientNumber( "torquelimit", 0 )
	local width		= self:GetClientNumber( "width", 1 )
	local friction		= self:GetClientNumber( "friction", 0 )
	local physdis		= util.tobool( self:GetClientNumber( "physdisable", 0 ) )

	local Bone1, Bone2 = self:GetBone(1),   self:GetBone(2)
	local LPos1, LPos2 = self:GetLocalPos(1),self:GetLocalPos(2)
	local Phys1 = self:GetPhys(1)

	if ( self:GetClientNumber( "entirecontrap" ) == 1 ) then
		local NumApp = 0
		local TargetEnts = {}
		local EntsTab = {}
		local ConstsTab = {}
		GetAllEnts(Ent1, TargetEnts, EntsTab, ConstsTab)
		for key,CurrentEnt in pairs(TargetEnts) do
			if ( CurrentEnt and CurrentEnt:IsValid() ) then
				if !(CurrentEnt == Ent2 ) then
					local CurrentPhys = CurrentEnt:GetPhysicsObject()
					if ( CurrentPhys:IsValid() ) then
						/*if autorotate then
							local angle = CurrentPhys:RotateAroundAxis( Vector( 0, 0, 1 ), 0 )
							angle.p = (math.Round(angle.p/45))*45
							angle.r = (math.Round(angle.r/45))*45
							angle.y = (math.Round(angle.y/45))*45
							CurrentPhys:SetAngles( angle )
							CurrentPhys:Wake()
						end*/
						CurrentPhys:EnableCollisions( !nocollideall )
						CurrentPhys:EnableMotion( !freeze )
						CurrentPhys:Wake()
						if ( CurrentEnt:GetPhysicsObjectCount() < 2 ) then //not a ragdoll
							if ( mode == 1 ) then //Apply
								CurrentEnt:DrawShadow( !shadowdisable )
								if physdis then
									CurrentEnt:SetMoveType(MOVETYPE_NONE)
									CurrentEnt.PhysgunDisabled = disablephysgun
									CurrentEnt:SetUnFreezable( disablephysgun )
								else
									CurrentEnt:SetMoveType(MOVETYPE_VPHYSICS)
									CurrentEnt.PhysgunDisabled = false
									CurrentEnt:SetUnFreezable( false )
								end
							elseif ( mode == 2 ) then //Rotate
								self:SendMessage("Sorry, No entire contraption rotating... yet")
								return false//TODO: Entire contrpation rotaton
							elseif ( mode == 3 ) then //move
								self:SendMessage("Sorry, No entire contraption moving... yet")
								return false//todo: entire contraption move/snap
							elseif ( mode == 4 ) then //weld
								local constraint = constraint.Weld( CurrentEnt, Ent2, 0, Bone2, forcelimit,  util.tobool( nocollide ) )
								if (constraint) then
									undo.Create("Precision_Weld")
									undo.AddEntity( constraint )
									undo.SetPlayer( self:GetOwner() )
									undo.Finish()
									self:GetOwner():AddCleanup( "constraints", constraint )
								end
							elseif ( mode == 5 ) then //doaxis
								local constraint = constraint.Axis( CurrentEnt, Ent2, 0, Bone2, LPos1, LPos2, forcelimit, torquelimit, friction, nocollide )
								if (constraint) then
									undo.Create("Precision_Axis")
									undo.AddEntity( constraint )
									undo.SetPlayer( self:GetOwner() )
									undo.Finish()
									self:GetOwner():AddCleanup( "constraints", constraint )
								end
							elseif ( mode == 6 ) then //ballsocket
								local constraint = constraint.Ballsocket( CurrentEnt, Ent2, 0, Bone2, LPos2, forcelimit, torquelimit, nocollide )
								if (constraint) then
									undo.Create("Precision_Ballsocket")
									undo.AddEntity( constraint )
									undo.SetPlayer( self:GetOwner() )
									undo.Finish()
									self:GetOwner():AddCleanup( "constraints", constraint )
								end
							elseif ( mode == 7 ) then //adv ballsocket
								local constraint = constraint.AdvBallsocket( CurrentEnt, Ent2, 0, Bone2, LPos1, LPos2, forcelimit, torquelimit, self:GetClientNumber( "XRotMin", -180 ), self:GetClientNumber( "YRotMin", -180 ), self:GetClientNumber( "ZRotMin", -180 ), self:GetClientNumber( "XRotMax", 180 ), self:GetClientNumber( "YRotMax", 180 ), self:GetClientNumber( "ZRotMax", 180 ), self:GetClientNumber( "XRotFric", 0 ), self:GetClientNumber( "YRotFric", 0 ), self:GetClientNumber( "ZRotFric", 0 ), self:GetClientNumber( "FreeMov", 0 ), nocollide )
								if (constraint) then
									undo.Create("Precision_Advanced_Ballsocket")
									undo.AddEntity( constraint )
									undo.SetPlayer( self:GetOwner() )
									undo.Finish()
									self:GetOwner():AddCleanup( "constraints", constraint )
								end
							elseif ( mode == 8 ) then //slider
								local constraint0 = constraint.Slider( CurrentEnt, Ent2, 0, Bone2, LPos1, LPos2, width )
								if (constraint0) then
									undo.Create("Precision_Slider")
									if ( self:GetClientNumber( "disablesliderfix" ) == 0 ) then
										local constraint2 = constraint.AdvBallsocket( Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, 0, 0, 0, -180, -180, 0, 180, 180, 50, 0, 0, 1, 0 )
										if (constraint2) then
											undo.AddEntity( constraint2 )
										end
										local constraint3 = constraint.AdvBallsocket( Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, 0, 0, -180, 0, -180, 180, 0, 180, 0, 50, 0, 1, 0 )
										if (constraint3) then
											undo.AddEntity( constraint3 )
										end
										local constraint4 = constraint.AdvBallsocket( Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, 0, 0, -180, -180, 0, 180, 180, 0, 0, 0, 50, 1, 0 )
										if (constraint4) then
											undo.AddEntity( constraint4 )
										end
									end
									undo.AddEntity( constraint0 )
									undo.SetPlayer( self:GetOwner() )
									undo.Finish()
									self:GetOwner():AddCleanup( "constraints", constraint0 )
								end
							end
							if (  util.tobool( nocollide ) && iNum != 0) then // not weld/axis/ballsocket or single application
								local constraint = constraint.NoCollide(CurrentEnt, Ent2, 0, Bone2)
							end
						end
						if ( mode == 9 ) then //parent
							self:DoParent( CurrentEnt, Ent2 )
						end
					end
				end
			end
			NumApp = NumApp + 1
		end
		self:SendMessage( NumApp .. " items constrained." )
	else
		if ( mode == 1 ) then //Apply
			if ( !Ent1:GetParent():IsValid() ) then
				Phys1:EnableCollisions( !nocollideall )
				if physdis then
					self:SendMessage( "Item Physics Disabled." )
					local disablephysgun = false
					if ( self:GetClientNumber( "allowphysgun" ) == 0 ) then disablephysgun = true end
					Ent1:SetMoveType(MOVETYPE_NONE)
					Ent1.PhysgunDisabled = disablephysgun
					Ent1:SetUnFreezable( disablephysgun )
					if ( Ent1:GetMoveType() == 0 ) then
						Ent1:SetPos( Phys1:GetPos() )
						Ent1:SetAngles( Phys1:GetAngles() )
					end
				else
					Ent1:SetMoveType(MOVETYPE_VPHYSICS)
					Ent1.PhysgunDisabled = false
					Ent1:SetUnFreezable( false )
				end
			end
			Ent1:DrawShadow( !util.tobool( self:GetClientNumber( "ShadowDisable", 0 ) ) )
		elseif ( mode == 2 ) then //Rotate
			self:SendMessage("Rotate completed")
		elseif ( mode == 3 ) then //move
			self:SendMessage("Snap move completed")
		elseif ( mode == 4 ) then //weld
			local constraint = constraint.Weld( Ent1, Ent2, Bone1, Bone2, forcelimit,  util.tobool( nocollide ) )
			if (constraint) then
				self:SendMessage( "Target welded." )
				undo.Create("Precision_Weld")
				undo.AddEntity( constraint )
				undo.SetPlayer( self:GetOwner() )
				undo.Finish()
				self:GetOwner():AddCleanup( "constraints", constraint )
			end
		elseif ( mode == 5 ) then //doaxis
			local constraint = constraint.Axis( Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, forcelimit, torquelimit, friction, nocollide )
			if (constraint) then
				self:SendMessage( "Target Axised." )
				undo.Create("Precision_Axis")
				undo.AddEntity( constraint )
				undo.SetPlayer( self:GetOwner() )
				undo.Finish()
				self:GetOwner():AddCleanup( "constraints", constraint )
			end
		elseif ( mode == 6 ) then //ballsocket
			local constraint = constraint.Ballsocket( Ent1, Ent2, Bone1, Bone2, LPos2, forcelimit, torquelimit, nocollide )
			if (constraint) then
				self:SendMessage( "Target Ballsocketed." )
				undo.Create("Precision_Ballsocket")
				undo.AddEntity( constraint )
				undo.SetPlayer( self:GetOwner() )
				undo.Finish()
				self:GetOwner():AddCleanup( "constraints", constraint )
			end
		elseif ( mode == 7 ) then //adv ballsocket
			local constraint = constraint.AdvBallsocket( Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, forcelimit, torquelimit, self:GetClientNumber( "XRotMin", -180 ), self:GetClientNumber( "YRotMin", -180 ), self:GetClientNumber( "ZRotMin", -180 ), self:GetClientNumber( "XRotMax", 180 ), self:GetClientNumber( "YRotMax", 180 ), self:GetClientNumber( "ZRotMax", 180 ), self:GetClientNumber( "XRotFric", 0 ), self:GetClientNumber( "YRotFric", 0 ), self:GetClientNumber( "ZRotFric", 0 ), self:GetClientNumber( "FreeMov", 0 ), nocollide )
			if (constraint) then
				self:SendMessage( "Target Adv Ballsocketed." )
				undo.Create("Precision_Advanced_Ballsocket")
				undo.AddEntity( constraint )
				undo.SetPlayer( self:GetOwner() )
				undo.Finish()
				self:GetOwner():AddCleanup( "constraints", constraint )
			end
		elseif ( mode == 8 ) then //slider
			local constraint0 = constraint.Slider( Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, width )
			if (constraint0) then
				self:SendMessage( "Target Slidered." )
				undo.Create("Precision_Slider")
				if ( self:GetClientNumber( "disablesliderfix" ) == 0 ) then
					local constraint2 = constraint.AdvBallsocket( Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, 0, 0, 0, -180, -180, 0, 180, 180, 50, 0, 0, 1, 0 )
					if (constraint2) then
						undo.AddEntity( constraint2 )
					end
					local constraint3 = constraint.AdvBallsocket( Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, 0, 0, -180, 0, -180, 180, 0, 180, 0, 50, 0, 1, 0 )
					if (constraint3) then
						undo.AddEntity( constraint3 )
					end
					local constraint4 = constraint.AdvBallsocket( Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, 0, 0, -180, -180, 0, 180, 180, 0, 0, 0, 50, 1, 0 )
					if (constraint4) then
						undo.AddEntity( constraint4 )
					end
				end
				undo.AddEntity( constraint0 )
				undo.SetPlayer( self:GetOwner() )
				undo.Finish()
				self:GetOwner():AddCleanup( "constraints", constraint0 )
				self:GetOwner():AddCleanup( "constraints", constraint2 )
				self:GetOwner():AddCleanup( "constraints", constraint3 )
				self:GetOwner():AddCleanup( "constraints", constraint4 )
			end
		end
		if (  util.tobool( nocollide ) && iNum != 0) then // not weld/axis/ballsocket or single application
			//self:SendMessage( "Current settings applied." )
			local constraint = constraint.NoCollide(Ent1, Ent2, Bone1, Bone2)
		end
		if ( mode == 9 ) then //parent
			Phys1:EnableMotion( 0 )
			self:DoParent( Ent1, Ent2 )
		else
			Phys1:EnableMotion( !freeze )
			Phys1:Wake()
		end
	end
	// Clear the objects so we're ready to go again
	if ( inuse == self:GetOwner():GetName() ) then
		inuse = nil
	end
	self:ClearObjects()
end

function TOOL:DoNoConstraint( trace )
	if ( CLIENT ) then
		self:ClearObjects()
		return true
	end

	// Get client's CVars
	local freeze		= util.tobool( self:GetClientNumber( "freeze", 1 ) )
	local nocollideall	= util.tobool( self:GetClientNumber( "nocollideall", 0 ) )
	local physdis		= util.tobool( self:GetClientNumber( "physdisable", 0 ) )
	local autorotate	= util.tobool( self:GetClientNumber( "autorotate", 0 ) )
	local shadowdisable	= util.tobool( self:GetClientNumber( "ShadowDisable", 0 ) )
	local disablephysgun	= !util.tobool( self:GetClientNumber( "allowphysgun", 0 ) )

	// Get information we're about to use
	local Ent1 = trace.Entity
	local Phys1 = trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone )

	// Something happened, the entity became invalid half way through
	// Finish it.
	if ( !Ent1:IsValid() ) then
		self:ClearObjects()
		return false
	end
	if ( self:GetClientNumber( "entirecontrap" ) == 1) then
		local NumApp = 0
		local TargetEnts = {}
		local EntsTab = {}
		local ConstsTab = {}
		GetAllEnts(Ent1, TargetEnts, EntsTab, ConstsTab)

		local angle = Vector(0,0,1)
		local anglechange = Vector(0,0,1)
		
		if ( autorotate ) then
			angle = Phys1:RotateAroundAxis( Vector( 0, 0, 1 ), 0 )
			anglechange = Vector( angle.p - (math.Round(angle.p/45))*45, angle.r - (math.Round(angle.r/45))*45, angle.y - (math.Round(angle.y/45))*45 )
			//angle.p = (math.Round(angle.p/45))*45
			//angle.r = (math.Round(angle.r/45))*45// pointless rotating individual more than entire
			angle.y = (math.Round(angle.y/45))*45
			Phys1:SetAngles( angle )
			Phys1:Wake()
		end

		for key,CurrentEnt in pairs(TargetEnts) do
			if ( CurrentEnt and CurrentEnt:IsValid() ) then
				local CurrentPhys = CurrentEnt:GetPhysicsObject()
				if ( CurrentPhys:IsValid() ) then
					if autorotate then
						if !( CurrentEnt == Ent1 ) then
							local distance = math.sqrt(math.pow((CurrentEnt:GetPos().X-Ent1:GetPos().X),2)+math.pow((CurrentEnt:GetPos().Y-Ent1:GetPos().Y),2))
							local theta = math.atan((CurrentEnt:GetPos().Y-Ent1:GetPos().Y) / (CurrentEnt:GetPos().X-Ent1:GetPos().X)) - math.rad(anglechange.Z)
							if (CurrentEnt:GetPos().X-Ent1:GetPos().X) < 0 then
								CurrentEnt:SetPos( Vector( Ent1:GetPos().X - (distance*(math.cos(theta))), Ent1:GetPos().Y - (distance*(math.sin(theta))), CurrentEnt:GetPos().Z ) )
							else
								CurrentEnt:SetPos( Vector( Ent1:GetPos().X + (distance*(math.cos(theta))), Ent1:GetPos().Y + (distance*(math.sin(theta))), CurrentEnt:GetPos().Z ) )
							end
							CurrentPhys:SetAngles( CurrentPhys:RotateAroundAxis( Vector( 0, 0, -1 ), anglechange.Z ) )
							CurrentPhys:Wake()
						end
					end
					if ( !CurrentEnt:GetParent():IsValid() ) then
						CurrentPhys:EnableCollisions( !nocollideall )
						CurrentPhys:EnableMotion( !freeze )
						CurrentPhys:Wake()
					end
				end
				if ( !CurrentEnt:GetParent():IsValid() ) then
					if physdis then
						CurrentEnt:SetMoveType(MOVETYPE_NONE)
						CurrentEnt.PhysgunDisabled = disablephysgun
						CurrentEnt:SetUnFreezable( disablephysgun )
					else
						CurrentEnt:SetMoveType(MOVETYPE_VPHYSICS)
						CurrentEnt.PhysgunDisabled = false
						CurrentEnt:SetUnFreezable( false )
					end
				end
				CurrentEnt:DrawShadow( !shadowdisable )
			end
			NumApp = NumApp + 1
		end
		self:SendMessage( NumApp .. " items targeted :" )
	else
		if autorotate then
			local angle = Phys1:RotateAroundAxis( Vector( 0, 0, 1 ), 0 )
			angle.p = (math.Round(angle.p/45))*45
			angle.r = (math.Round(angle.r/45))*45
			angle.y = (math.Round(angle.y/45))*45
			Phys1:SetAngles( angle )
			Phys1:Wake()
		end
		Phys1:EnableCollisions( !nocollideall )
		if ( !Ent1:GetParent():IsValid() ) then
			if physdis then
				Ent1:SetMoveType(MOVETYPE_NONE)
				Ent1.PhysgunDisabled = disablephysgun
				Ent1:SetUnFreezable( disablephysgun )
			else
				Ent1:SetMoveType(MOVETYPE_VPHYSICS)
				Ent1.PhysgunDisabled = false
				Ent1:SetUnFreezable( false )
			end
			Phys1:EnableMotion( !freeze )
			Phys1:Wake()
		end
		Ent1:DrawShadow( !shadowdisable )
	end

	// Clear the objects so we're ready to go again, though shouldn't be any here
	if ( inuse == self:GetOwner():GetName() ) then
		inuse = nil
	end
	self:ClearObjects()
end

function TOOL:SendMessage( message )
	if ( self:GetClientNumber( "enablefeedback" ) == 0 ) then return end
	if ( self:GetClientNumber( "chatfeedback" ) == 1 ) then
		self:GetOwner():PrintMessage( HUD_PRINTTALK, "Tool: " .. message )
	else
		self:GetOwner():PrintMessage( HUD_PRINTCENTER, message )
	end
end

function TOOL:LeftClick( trace )

	if ( iNum == 0 ) then
		trace.Entity:SetMoveType(MOVETYPE_VPHYSICS)
	end
	local iNum = self:NumObjects()
	local Phys = trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone )

	if ( iNum < 2 ) then
		// If there's no physics object then we can't constraint it!
		if (  SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone )  && ( !trace.Entity:GetParent():IsValid() || ! self:GetClientNumber( "removal" ) == 1 || !self:GetClientNumber( "mode" ) == 9) ) then
			if  !( (self:GetClientNumber( "mode" ) < 4 && iNum == 0)) then
				return false
			end
		end

		// Don't weld players, or to players
		if ( trace.Entity:IsPlayer() ) then return false end

		// Don't do anything with stuff without any physics..
		if ( SERVER && !Phys:IsValid() && ( !trace.Entity:GetParent():IsValid() || !self:GetClientNumber( "removal" ) == 1 || !self:GetClientNumber( "mode" ) == 9 ) ) then
			if  !( self:GetClientNumber( "mode" ) < 4 && iNum == 0 ) then
				return false
			end
		end
	end

	if (iNum == 0) then
		local mode = self:GetClientNumber( "mode" )
		if ( !trace.Entity:IsValid() ) then return false end

		if ( mode == 10 ) then//Reweld mode
			if ( CLIENT ) then return true end
			local TargetEnts = {}
			local EntsTab = {}
			local ConstsTab = {}
			local forcelimit 	= self:GetClientNumber( "forcelimit", 0 )
			local freeze		= util.tobool( self:GetClientNumber( "freeze", 1 ) )
			local nocollide		= ( self:GetClientNumber( "nocollide" ) == 1 )

			GetAllEnts(trace.Entity, TargetEnts, EntsTab, ConstsTab)
			ConstsTab = GetAllConstraints( EntsTab )

			local TotalConst = table.Count(ConstsTab)
			local NumFix = 0
			for key,CurrentEnt in pairs(TargetEnts) do
				CurrentEnt:GetPhysicsObject():EnableMotion( false )
				constraint.RemoveConstraints( CurrentEnt, "Weld" )
			end

			for k,CurrentConstr in pairs(ConstsTab) do
				if ( CurrentConstr.Constraint.Type == "Weld" ) then
					NumFix = NumFix + 1
					// wtf? removeconstraints fails to let it re-weld with nocollide without adding a delay
					timer.Simple( 0.1, function() 
					
						constraint.Weld( CurrentConstr.Entity[1].Entity, CurrentConstr.Entity[2].Entity, CurrentConstr.Entity[1].Bone, CurrentConstr.Entity[2].Bone, forcelimit, nocollide )
					
					end)
				end
			end
			
			if ( !freeze ) then
				local phys
				for key,CurrentEnt in pairs(TargetEnts) do
					phys = CurrentEnt:GetPhysicsObject()
					timer.Simple( 0.1, function()
						phys.EnableMotion( true )
					end)
				end
			end
			self:SendMessage( TotalConst .. " total constraints found." )
			self:SendMessage( NumFix .. " welds redone." )
			return NumFix > 0
		elseif ( self:GetClientNumber( "removal" ) == 1 && mode > 3 ) then//Constraint mode - Attempt to remove.
			if ( CLIENT ) then return true end
			local StartEnt = trace.Entity
			local  bool = false
			if ( self:GetClientNumber( "entirecontrap" ) == 1 ) then
				local NumRem = 0
				local TargetEnts = {}
				local EntsTab = {}
				local ConstsTab = {}
				GetAllEnts(StartEnt, TargetEnts, EntsTab, ConstsTab)
				for key,CurrentEnt in pairs(TargetEnts) do
					if ( CurrentEnt and CurrentEnt:IsValid() ) then
						/*if ( mode == 1 ) then
							bool = constraint.RemoveConstraints( CurrentEnt, "NoCollide" )
							Phys:EnableCollisions(true)
						else*/if ( mode == 4 ) then
							bool = constraint.RemoveConstraints( CurrentEnt, "Weld" )
						elseif ( mode == 5 ) then
							bool = constraint.RemoveConstraints( CurrentEnt, "Axis" )
						elseif ( mode == 6 ) then
							bool = constraint.RemoveConstraints( CurrentEnt, "Ballsocket" )
						elseif ( mode == 7 ) then
							bool = constraint.RemoveConstraints( CurrentEnt, "AdvBallsocket" )
						elseif ( mode == 8 ) then
							bool = constraint.RemoveConstraints( CurrentEnt, "Slider" )
						elseif ( mode == 9 ) then
							bool = CurrentEnt:GetParent():IsValid()
							if ( bool ) then
								self:UndoParent( CurrentEnt )
							end
						end
					end
					if ( bool ) then NumRem = NumRem + 1 end
				end
				self:SendMessage( NumRem .. " constraints removed." )
			else
				if ( mode == 4 ) then
					bool = constraint.RemoveConstraints( StartEnt, "Weld" )
				elseif ( mode == 5 ) then
					bool = constraint.RemoveConstraints( StartEnt, "Axis" )
				elseif ( mode == 6 ) then
					bool = constraint.RemoveConstraints( StartEnt, "Ballsocket" )
				elseif ( mode == 7 ) then
					bool = constraint.RemoveConstraints( StartEnt, "AdvBallsocket" )
				elseif ( mode == 8 ) then
					bool = constraint.RemoveConstraints( StartEnt, "Slider" )
				elseif ( mode == 9 ) then
					bool = StartEnt:GetParent():IsValid()
					if ( bool ) then
						self:UndoParent( StartEnt )
					end
				end
				if bool then
					self:SendMessage( "Constraint removed." )
				else
					self:SendMessage( "No constraint to remove." )
				end
			end
			return bool
		elseif (self:GetClientNumber( "Move" ) == 0 && self:GetClientNumber( "mode" ) != 3) || self:GetClientNumber( "mode" ) < 3 then 
			if self:GetClientNumber( "mode" ) == 2 then
				if ( CLIENT ) then return true end
				//self:SetStage(2)
				//iNum = 2

				local oldposu = trace.Entity:GetPos()
				local oldangles = trace.Entity:GetAngles()

				local function MoveUndo( Undo, Entity, oldposu, oldangles )
					if Entity:IsValid() then
						Entity:SetAngles( oldangles )
						Entity:SetPos( oldposu )
					end
				end

				if ( self:GetClientNumber( "rotateundo" )) then
					undo.Create("Precision_Rotate")
						undo.SetPlayer(self:GetOwner())
						undo.AddFunction( MoveUndo, trace.Entity, oldposu, oldangles )
					undo.Finish()
				end

				Phys:EnableMotion( false ) //else it drifts
				
				local rotation = math.Clamp(self:GetClientNumber( "rotation" ),0.02,90)
				
				if ( inuse == nil || inuse == self:GetOwner():GetName() ) then
					inuse = self:GetOwner():GetName()
					axis = trace.HitNormal
					axisY = axis:Cross(trace.Entity:GetUp())
					if self:WithinABit( axisY, Vector(0,0,0) ) then
						axisY = axis:Cross(trace.Entity:GetForward())
					end
					axisZ = axisY:Cross(axis)
					realdegrees = 0
					lastdegrees = -((rotation/2) % rotation)
					realdegreesY = 0
					lastdegreesY = -((rotation/2) % rotation)
					realdegreesZ = 0
					lastdegreesZ = -((rotation/2) % rotation)
					OldPos = trace.HitPos
				else
					//inuse2 = self:GetOwner():GetName()
					axis2 = trace.HitNormal
					axis2Y = axis2:Cross(trace.Entity:GetUp())
					if self:WithinABit( axis2Y, Vector(0,0,0) ) then
						axis2Y = axis2:Cross(trace.Entity:GetForward())
					end
					axis2Z = trace.Entity:GetUp()//axis2Y:Cross(axis2)
					realdegrees2 = 0
					lastdegrees2 = -((rotation/2) % rotation)
					realdegrees2Y = 0
					lastdegrees2Y = -((rotation/2) % rotation)
					realdegrees2Z = 0
					lastdegrees2Z = -((rotation/2) % rotation)
					OldPos2 = trace.HitPos
				end
				self:SetObject( iNum + 2, trace.Entity, trace.HitPos, Phys, trace.PhysicsBone, trace.HitNormal )
			elseif ( self:GetClientNumber( "mode" ) == 1 ) then
				self:SendMessage( "Current settings applied." )//client doesn't get this far? why?
				self:DoNoConstraint( trace ) //both 0 and not needing a second object to constrain.. apply right away
				return true
			end
		end
	end
	self:SetObject( iNum + 1, trace.Entity, trace.HitPos, Phys, trace.PhysicsBone, trace.HitNormal )

	if ( iNum > 1 ) then
		self:DoConstraint()
	elseif ( iNum == 1 ) then
		if ( self:GetEnt(1) == self:GetEnt(2) ) then
			SavedPos = self:GetPos(2)
			//self:SendMessage("Fool! You can't constrain somthing to itself")
			//self:ClearObjects()
			//return false
		end
		local offset		= self:GetClientNumber( "offset" )
		local move		= (self:GetClientNumber( "move" ) == 1 && self:GetClientNumber( "mode" ) > 2) || self:GetClientNumber( "mode" ) == 3
		local mode = self:GetClientNumber( "mode" )
		if ( move && mode < 9 ) then//No move on parent
			if ( CLIENT ) then
				self:ReleaseGhostEntity()
				return true
			end

			// Get information we're about to use
			local Norm1, Norm2 = self:GetNormal(1),   self:GetNormal(2)
			local Phys1, Phys2 = self:GetPhys(1),     self:GetPhys(2)
			
			local Ang1, Ang2 = Norm1:Angle(), (Norm2 * -1):Angle()
			if self:GetClientNumber( "autorotate" ) == 1 then
				Ang2.p = (math.Round(Ang2.p/45))*45
				Ang2.r = (math.Round(Ang2.r/45))*45
				Ang2.y = (math.Round(Ang2.y/45))*45
				Norm2 = Ang2:Forward() * -1
			end


			local oldposu = self:GetEnt(1):GetPos()
			local oldangles = self:GetEnt(1):GetAngles()

			local function MoveUndo( Undo, Entity, oldposu, oldangles )
				if Entity:IsValid() then
					Entity:SetAngles( oldangles )
					Entity:SetPos( oldposu )
				end
			end
			if self:GetClientNumber( "moveundo" ) == 1 then
			undo.Create("Precision Move")
				undo.SetPlayer(self:GetOwner())
				undo.AddFunction( MoveUndo, self:GetEnt(1), oldposu, oldangles )
			undo.Finish()
			end

			local rotation = math.Clamp(self:GetClientNumber( "rotation" ),0.02,90)
			if ( (self:GetClientNumber( "rotate" ) == 1 && mode != 1) || mode == 2) then//Set axies for rotation mode directions
				if ( inuse == nil || inuse == self:GetOwner():GetName() ) then
					inuse = self:GetOwner():GetName()
					axis = Norm2
					axisY = axis:Cross(Vector(0,1,0))
					if self:WithinABit( axisY, Vector(0,0,0) ) then
						axisY = axis:Cross(Vector(0,0,1))
					end
					axisY:Normalize()
					axisZ = axisY:Cross(axis)
					axisZ:Normalize()
					realdegrees = 0
					lastdegrees = -((rotation/2) % rotation)
					realdegreesY = 0
					lastdegreesY = -((rotation/2) % rotation)
					realdegreesZ = 0
					lastdegreesZ = -((rotation/2) % rotation)
				else
					axis2 = Norm2
					axis2Y = axis2:Cross(Vector(0,1,0))
					if self:WithinABit( axis2Y, Vector(0,0,0) ) then
						axis2Y = axis2:Cross(Vector(0,0,1))
					end
					axis2Y:Normalize()
					axis2Z = axis2Y:Cross(axis2)
					axis2Z:Normalize()
					realdegrees2 = 0
					lastdegrees2 = -((rotation/2) % rotation)
					realdegrees2Y = 0
					lastdegrees2Y = -((rotation/2) % rotation)
					realdegrees2Z = 0
					lastdegrees2Z = -((rotation/2) % rotation)
				end
			else
				if ( inuse == nil || inuse == self:GetOwner():GetName() ) then
					inuse = self:GetOwner():GetName()
					axis = Norm2
					axisY = axis:Cross(Vector(0,1,0))
					if self:WithinABit( axisY, Vector(0,0,0) ) then
						axisY = axis:Cross(Vector(0,0,1))
					end
					axisY:Normalize()
					axisZ = axisY:Cross(axis)
					axisZ:Normalize()
				else
					axis2 = Norm2
					axis2Y = axis2:Cross(Vector(0,1,0))
					if self:WithinABit( axis2Y, Vector(0,0,0) ) then
						axis2Y = axis2:Cross(Vector(0,0,1))
					end
					axis2Y:Normalize()
					axis2Z = axis2Y:Cross(axis2)
					axis2Z:Normalize()
				end
			end



			local TargetAngle = Phys1:AlignAngles( Ang1, Ang2 )//Get angle Phys1 would be at if difference between Ang1 and Ang2 was added


			if self:GetClientNumber( "autorotate" ) == 1 then
				TargetAngle.p = (math.Round(TargetAngle.p/45))*45
				TargetAngle.r = (math.Round(TargetAngle.r/45))*45
				TargetAngle.y = (math.Round(TargetAngle.y/45))*45
			end

			Phys1:SetAngles( TargetAngle )


			local NewOffset = offset
			local offsetpercent		= self:GetClientNumber( "offsetpercent" ) == 1
			if ( offsetpercent ) then
				local  Ent2  = self:GetEnt(2)
				local glower = Ent2:OBBMins()
				local gupper = Ent2:OBBMaxs()
				local height = math.abs(gupper.z - glower.z) -0.5
				if self:WithinABit(Norm2,Ent2:GetForward()) then
					height = math.abs(gupper.x - glower.x)-0.5
				elseif self:WithinABit(Norm2,Ent2:GetRight()) then
					height = math.abs(gupper.y - glower.y)-0.5
				end
				NewOffset = NewOffset / 100
				NewOffset = NewOffset * height
			end
			Norm2 = Norm2 * (-0.0625 + NewOffset)
			local TargetPos = self:GetPos(2) + (Phys1:GetPos() - self:GetPos(1)) + (Norm2)
			//self:SetPos(2)

			// Set the position

			Phys1:SetPos( TargetPos )
			Phys1:EnableMotion( false )

			// Wake up the physics object so that the entity updates
			Phys1:Wake()
		end //end move check

		self:ReleaseGhostEntity()
		local rotate		= (self:GetClientNumber( "rotate" ) == 1 && mode > 1 && ((self:GetClientNumber( "move" ) == 1 && mode > 2) || mode == 3)) || mode == 2
		if ( rotate && mode < 9 ) then //here be third click
			self:SetStage( iNum+1 )
			if ( inuse == nil || inuse == self:GetOwner():GetName() ) then
				inuse = self:GetOwner():GetName()
			end
		else
			self:DoConstraint()
		end
	else
		local move		= (self:GetClientNumber( "move" ) == 1 && self:GetClientNumber( "mode" ) > 2) || self:GetClientNumber( "mode" ) == 3
		if ( move ) then
			self:StartGhostEntity( trace.Entity )
		end
		self:SetStage( iNum+1 )
	end
	return true
end

function TOOL:WithinABit( v1, v2 )
	local tol = 0.1
	local da = v1.x-v2.x
	local db = v1.y-v2.y
	local dc = v1.z-v2.z
	if da < tol && da > -tol && db < tol && db > -tol && dc < tol && dc > -tol then
		return true
	else
		da = v1.x+v2.x
		db = v1.y+v2.y
		dc = v1.z+v2.z
		if da < tol && da > -tol && db < tol && db > -tol && dc < tol && dc > -tol then
			return true
		else
			return false
		end
	end
end

if ( SERVER ) then
	function GetAllEnts( Ent, OrderedEntList, EntsTab, ConstsTab )
		if ( Ent and Ent:IsValid() ) and ( !EntsTab[ Ent:EntIndex() ] ) then
			EntsTab[ Ent:EntIndex() ] = Ent
			table.insert(OrderedEntList, Ent)
			if ( !constraint.HasConstraints( Ent ) ) then return OrderedEntList end
			for key, ConstraintEntity in pairs( Ent.Constraints ) do
				if ( !ConstsTab[ ConstraintEntity ] ) then
					ConstsTab[ ConstraintEntity ] = true
					local ConstTable = ConstraintEntity:GetTable()
					for i=1, 6 do
						local e = ConstTable[ "Ent"..i ]
						if ( e and e:IsValid() ) and ( !EntsTab[ e:EntIndex() ] ) then
							GetAllEnts( e, OrderedEntList, EntsTab, ConstsTab )
						end
					end
				end
			end
		end
		return OrderedEntList
	end

	/*function DoWelds( ConstsTab, forcelimit, nocollide )
		for k,CurrentConstr in pairs(ConstsTab) do
			if ( CurrentConstr.Constraint.Type == "Weld" ) then
				NumFix = NumFix + 1
				constraint.Weld( CurrentConstr.Entity[1].Entity, CurrentConstr.Entity[2].Entity, CurrentConstr.Entity[1].Bone, CurrentConstr.Entity[2].Bone, forcelimit, nocollide )
			end
		end
	end*/
	
	function GetAllConstraints( EntsTab )
		local ConstsTab = {}
		for key, Ent in pairs( EntsTab ) do
			if ( Ent and Ent:IsValid() ) then
				local MyTable = constraint.GetTable( Ent )
				for key, Constraint in pairs( MyTable ) do
					if ( !ConstsTab[ Constraint.Constraint ] ) then
						ConstsTab[ Constraint.Constraint ] = Constraint
					end
				end
			end
		end
		return ConstsTab
	end
end

function TOOL:UpdateCustomGhost( ghost, player, offset )
	// Ghost is identically buggy to that of easyweld...  welding two frozen props and two unfrozen props yields different ghosts even if identical allignment
	if (ghost == nil) then return end
	if (!ghost:IsValid()) then ghost = nil return end

	local tr = util.GetPlayerTrace( player, player:GetAimVector() )//REUPLOAD YOU STUPID WORKSHOP TOOL! (With 'Player' changing to 'player' it doesn't update the file :/)
	local trace = util.TraceLine( tr )
	if (!trace.Hit) then return end

	local Ang1, Ang2 = self:GetNormal(1):Angle(), (trace.HitNormal * -1):Angle()
	local TargetAngle = self:GetEnt(1):AlignAngles( Ang1, Ang2 )

	self.GhostEntity:SetPos( self:GetEnt(1):GetPos() )
	
	if self:GetClientNumber( "autorotate" ) == 1 then
		TargetAngle.p = (math.Round(TargetAngle.p/45))*45
		TargetAngle.r = (math.Round(TargetAngle.r/45))*45
		TargetAngle.y = (math.Round(TargetAngle.y/45))*45
	end
	self.GhostEntity:SetAngles( TargetAngle )

	local TraceNormal = trace.HitNormal

	local offsetpercent		= self:GetClientNumber( "offsetpercent" ) == 1
	local NewOffset = offset
	if ( offsetpercent ) then
		local glower = trace.Entity:OBBMins()
		local gupper = trace.Entity:OBBMaxs()
		local height = math.abs(gupper.z - glower.z) -0.5
		if self:WithinABit(TraceNormal,trace.Entity:GetForward()) then
			height = math.abs(gupper.x - glower.x) -0.5
		elseif self:WithinABit(TraceNormal,trace.Entity:GetRight()) then
			height = math.abs(gupper.y - glower.y) -0.5
		end
		NewOffset = NewOffset / 100
		NewOffset = NewOffset * height
	end

	local TranslatedPos = ghost:LocalToWorld( self:GetLocalPos(1) )
	local TargetPos = trace.HitPos + (self:GetEnt(1):GetPos() - TranslatedPos) + (TraceNormal*NewOffset)

	self.GhostEntity:SetPos( TargetPos )
end

function TOOL:Think()
	if (self:NumObjects() < 1) then return end
	local Ent1 = self:GetEnt(1)
	if ( SERVER ) then
		if ( !Ent1:IsValid() ) then
			self:ClearObjects()
			return
		end
	end

	if self:NumObjects() == 1 && self:GetClientNumber( "mode" ) != 2 then
		if ( (self:GetClientNumber( "move" ) == 1 && self:GetClientNumber( "mode" ) > 2) || self:GetClientNumber( "mode" ) == 3 ) then
			if ( self:GetClientNumber( "mode" ) < 9 ) then//no move = no ghost in parent mode
				local offset		= self:GetClientNumber( "offset" )
				self:UpdateCustomGhost( self.GhostEntity, self:GetOwner(), offset )
			end
		end
	else
		local rotate		= (self:GetClientNumber( "rotate" ) == 1 && self:GetClientNumber( "mode" ) != 1) || self:GetClientNumber( "mode" ) == 2
		if ( SERVER && rotate ) then
			local offset		= self:GetClientNumber( "offset" )

			local Phys1 = self:GetPhys(1)

			local cmd = self:GetOwner():GetCurrentCommand()

			local rotation		= math.Clamp(self:GetClientNumber( "rotation" ),0.02,90)
			if ( rotation < 0.02 ) then rotation = 0.02 end
			local degrees = cmd:GetMouseX() * 0.02

			local newdegrees = 0
			local changedegrees = 0

			local angle = 0
			if( self:GetOwner():KeyDown( IN_RELOAD ) ) then
				if ( inuse == self:GetOwner():GetName() ) then
					realdegreesY = realdegreesY + degrees
					newdegrees =  realdegreesY - ((realdegreesY + (rotation/2)) % rotation)
					changedegrees = lastdegreesY - newdegrees
					lastdegreesY = newdegrees
					angle = Phys1:RotateAroundAxis( axisY , changedegrees )
				else
					realdegrees2Y = realdegrees2Y + degrees
					newdegrees =  realdegrees2Y - ((realdegrees2Y + (rotation/2)) % rotation)
					changedegrees = lastdegrees2Y - newdegrees
					lastdegrees2Y = newdegrees
					angle = Phys1:RotateAroundAxis( axisY2 , changedegrees )
				end
			elseif( self:GetOwner():KeyDown( IN_ATTACK2 ) ) then
				if ( inuse == self:GetOwner():GetName() ) then
					realdegreesZ = realdegreesZ + degrees
					newdegrees =  realdegreesZ - ((realdegreesZ + (rotation/2)) % rotation)
					changedegrees = lastdegreesZ - newdegrees
					lastdegreesZ = newdegrees
					angle = Phys1:RotateAroundAxis( axisZ , changedegrees )
				else
					realdegrees2Z = realdegrees2Z + degrees
					newdegrees =  realdegrees2Z - ((realdegrees2Z + (rotation/2)) % rotation)
					changedegrees = lastdegrees2Z - newdegrees
					lastdegrees2Z = newdegrees
					angle = Phys1:RotateAroundAxis( axisZ2 , changedegrees )
				end
			else
				if ( inuse == self:GetOwner():GetName() ) then
					realdegrees = realdegrees + degrees
					newdegrees =  realdegrees - ((realdegrees + (rotation/2)) % rotation)
					changedegrees = lastdegrees - newdegrees
					lastdegrees = newdegrees
					angle = Phys1:RotateAroundAxis( axis , changedegrees )
				else
					realdegrees2 = realdegrees2 + degrees
					newdegrees =  realdegrees2 - ((realdegrees2 + (rotation/2)) % rotation)
					changedegrees = lastdegrees2 - newdegrees
					lastdegrees2 = newdegrees
					angle = Phys1:RotateAroundAxis( axis2 , changedegrees )
				end
			end
			Phys1:SetAngles( angle )

			if ( ( self:GetClientNumber( "move" ) == 1 && self:GetClientNumber( "mode" ) > 2) || self:GetClientNumber( "mode" ) == 3 ) then
				local WPos2 = self:GetPos(2)
				local Ent2 = self:GetEnt(2)
				// Move so spots join up
				local Norm2 = self:GetNormal(2)

				local NewOffset = offset
				local offsetpercent		= self:GetClientNumber( "offsetpercent" ) == 1
				if ( offsetpercent ) then
					local glower = Ent2:OBBMins()
					local gupper = Ent2:OBBMaxs()
					local height = math.abs(gupper.z - glower.z) -0.5
					if self:WithinABit(Norm2,Ent2:GetForward()) then
						height = math.abs(gupper.x - glower.x) -0.5
					elseif self:WithinABit(Norm2,Ent2:GetRight()) then
						height = math.abs(gupper.y - glower.y) -0.5
					end
					NewOffset = NewOffset / 100
					NewOffset = NewOffset * height
				end

				Norm2 = Norm2 * (-0.0625 + NewOffset)
				local TargetPos = Vector(0,0,0)
				if ( self:GetEnt(1) == self:GetEnt(2) ) then
					TargetPos = SavedPos + (Phys1:GetPos() - self:GetPos(1)) + (Norm2)
				else
					TargetPos = WPos2 + (Phys1:GetPos() - self:GetPos(1)) + (Norm2)
				end
				Phys1:SetPos( TargetPos )
			else
				// Move so rotating on axis

				local TargetPos = (Phys1:GetPos() - self:GetPos(1))
				if ( inuse == self:GetOwner():GetName() ) then
					TargetPos = TargetPos + OldPos
				else
					TargetPos = TargetPos + OldPos2
				end
				Phys1:SetPos( TargetPos )
			end
			Phys1:Wake()
		end
	end
end

function TOOL:Nudge( trace, direction )
	if (!trace.Entity:IsValid() || trace.Entity:IsPlayer() ) then return false end
	local Phys1 = trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone )
	local offset		= self:GetClientNumber( "nudge" )
	//if ( offset == 0 ) then offset = 1 end
	local NewOffset = offset
	local offsetpercent		= self:GetClientNumber( "nudgepercent" ) == 1
	if ( offsetpercent ) then
		local glower = trace.Entity:OBBMins()
		local gupper = trace.Entity:OBBMaxs()
		local height = math.abs(gupper.z - glower.z) -0.5
		if self:WithinABit(trace.HitNormal,trace.Entity:GetForward()) then
			height = math.abs(gupper.x - glower.x)-0.5
		elseif self:WithinABit(trace.HitNormal,trace.Entity:GetRight()) then
			height = math.abs(gupper.y - glower.y)-0.5
		end
		NewOffset = NewOffset / 100
		NewOffset = NewOffset * height
	end

	if ( self:GetClientNumber( "entirecontrap" ) == 1 ) then
		local NumApp = 0
		local TargetEnts = {}
		local EntsTab = {}
		local ConstsTab = {}
		GetAllEnts(trace.Entity, TargetEnts, EntsTab, ConstsTab)
		for key,CurrentEnt in pairs(TargetEnts) do
			if ( CurrentEnt and CurrentEnt:IsValid() ) then
				local CurrentPhys = CurrentEnt:GetPhysicsObject()
				if ( CurrentPhys:IsValid() ) then

					/*if ( self:GetClientNumber( "nudgeundo" ) == 1 ) then
						local oldpos = CurrentPhys:GetPos()
						local function NudgeUndo( Undo, Entity, oldpos )
							if CurrentEnt:IsValid() then
								CurrentEnt:SetPos( oldpos )
							end
						end
						undo.Create("Nrecision Nudge")
							undo.SetPlayer(self:GetOwner())
							undo.AddFunction( NudgeUndo, CurrentEnt, oldpos )
						undo.Finish()
					end*/// todo: all in 1 undo for mass nudging

					local TargetPos = CurrentPhys:GetPos() + trace.HitNormal * NewOffset * direction
					CurrentPhys:SetPos( TargetPos )
					CurrentPhys:Wake()
					if (CurrentEnt:GetMoveType() == 0 ) then //phys disabled, so move manually
						CurrentEnt:SetPos( TargetPos )
					end

				end
			end
			NumApp = NumApp + 1
		end
		if ( direction == -1 ) then
			self:SendMessage( NumApp .. " items pushed." )
		elseif ( direction == 1 ) then
			self:SendMessage( NumApp .. " items pulled." )
		else
			self:SendMessage( NumApp .. " items nudged." )
		end
	else
		if ( self:GetClientNumber( "nudgeundo" ) == 1 ) then
			local oldpos = Phys1:GetPos()
			local function NudgeUndo( Undo, Entity, oldpos )
				if trace.Entity:IsValid() then
					trace.Entity:SetPos( oldpos )
				end
			end
			undo.Create("Precision PushPull")
				undo.SetPlayer(self:GetOwner())
				undo.AddFunction( NudgeUndo, trace.Entity, oldpos )
			undo.Finish()
		end
		local TargetPos = Phys1:GetPos() + trace.HitNormal * NewOffset * direction
		Phys1:SetPos( TargetPos )
		Phys1:Wake()
		if ( trace.Entity:GetMoveType() == 0 ) then
			trace.Entity:SetPos( TargetPos )
		end
		if ( direction == -1 ) then
			self:SendMessage( "target pushed." )
		elseif ( direction == 1 ) then
			self:SendMessage( "target pulled." )
		else
			self:SendMessage( "target nudged." )
		end
	end
	return true
end

function TOOL:RightClick( trace )
	local rotate = self:GetClientNumber( "rotate" ) == 1
	local mode = self:GetClientNumber( "mode" )
	if ( (mode == 2 && self:NumObjects() == 1) || (rotate && self:NumObjects() == 2 ) ) then
		if ( CLIENT ) then return false end
	else
		if ( CLIENT ) then return true end
		return self:Nudge( trace, -1 )
	end
end

function TOOL:Reload( trace )
	local rotate = self:GetClientNumber( "rotate" ) == 1
	local mode = self:GetClientNumber( "mode" )
	if ( (mode == 2 && self:NumObjects() == 1) || (rotate && self:NumObjects() == 2 ) ) then
		if ( CLIENT ) then return false end
	else
		if ( CLIENT ) then return true end
		return self:Nudge( trace, 1 )
	end
end

if CLIENT then

	
language.Add( "Tool.precision.name", "Precision Tool 0.97" )
language.Add( "Tool.precision.desc", "Accurately positions objects" )
language.Add( "Tool.precision.0", "Primary: Move/Apply | Secondary: Push | Reload: Pull" )
language.Add( "Tool.precision.1", "Target the second item. If enabled, this will move the first item.  (Swap weps to cancel)" )
language.Add( "Tool.precision.2", "Rotate enabled: Turn left and right to rotate the object (Hold reload or alt-fire for other rotation directions!)" )
//language.Add( "Tool.precision.nudge.Description",		"Distance to push/pull objects with altfire/reload" )

language.Add("Undone.precision", "Undone Precision Constraint")
language.Add("Undone.precision.nudge", "Undone Precision Nudge")
language.Add("Undone.precision.rotate", "Undone Precision Rotate")
language.Add("Undone.precision.move", "Undone Precision Move")
language.Add("Undone.precision.weld", "Undone Precision Weld")
language.Add("Undone.precision.axis", "Undone Precision Axis")
language.Add("Undone.precision.ballsocket", "Undone Precision Ballsocket")
language.Add("Undone.precision.advanced.ballsocket", "Undone Precision Advanced Ballsocket")
language.Add("Undone.precision.slider", "Undone Precision Slider")

	//function TOOL:Deploy()
	//end
	local showgenmenu = 0
	//local expandpresets = 0

	local function AddDefControls( Panel )
		Panel:ClearControls()

		Panel:AddControl("ComboBox",
		{
			Label = "#Presets",
			MenuButton = 1,
			Folder = "precision",
			Options = {},
			CVars =
			{
				[0] = "precision_offset",
				[1] = "precision_forcelimit",
				[2] = "precision_freeze",
				[3] = "precision_nocollide",
				[4] = "precision_nocollideall",
				[5] = "precision_rotation",
				[6] = "precision_rotate",
				[7] = "precision_torquelimit",
				[8] = "precision_friction",
				[9] = "precision_mode",
				[10] = "precision_width",
				[11] = "precision_offsetpercent",
				[12] = "precision_removal",
				[13] = "precision_move",
				[14] = "precision_physdisable",
				[15] = "precision_advballsocket",
				[16] = "precision_XRotMin",
				[17] = "precision_XRotMax",
				[18] = "precision_YRotMin",
				[19] = "precision_YRotMax",
				[20] = "precision_ZRotMin",
				[21] = "precision_ZRotMax",
				[22] = "precision_XRotFric",
				[23] = "precision_YRotFric",
				[24] = "precision_ZRotFric",
				[25] = "precision_FreeMov",
				[26] = "precision_ShadowDisable",
				[27] = "precision_allowphysgun",
				[28] = "precision_autorotate",
				[29] = "precision_massmode",
				[30] = "precision_nudge",
				[31] = "precision_nudgepercent",
				[32] = "precision_disablesliderfix"
			}
		})

		//Panel:AddControl( "Label", { Text = "Secondary attack pushes, Reload pulls by this amount:", Description	= "Phx 1x is 47.45, Small tiled cube is 11.8625 and thin is 3 exact units" }  )
		Panel:AddControl( "Slider",  { Label	= "Push/Pull Amount",
					Type	= "Float",
					Min		= 1,
					Max		= 100,
					Command = "precision_nudge",
					Description = "Distance to push/pull props with altfire/reload"}	 ):SetDecimals( 4 )


		Panel:AddControl( "Checkbox", { Label = "Push/Pull as Percent (%) of target's depth", Command = "precision_nudgepercent", Description = "Unchecked = Exact units, Checked = takes % of width from target prop when pushing/pulling" } )


		local user = LocalPlayer():GetInfoNum( "precision_user", 0 )
		local mode = LocalPlayer():GetInfoNum( "precision_mode", 0 )
		//Panel:AddControl( "Label", { Text = "Primary attack uses the tool's main mode.", Description	= "Select a mode and configure the options, be sure to try new things out!" }  )

		local list = vgui.Create("DListView")

		local height = 186 //All 10 shown
		if ( user < 2 ) then
			height = 118 //6 shown
		elseif ( user < 3 ) then
			height = 152 //8 shown
		end

		list:SetSize(30,height)
		//list:SizeToContents()
		list:AddColumn("Tool Mode")
		list:SetMultiSelect(false)
		function list:OnRowSelected(LineID, line)
			if not (mode == LineID) then
				RunConsoleCommand("precision_setmode", LineID)
			end
		end

		if ( mode == 1 ) then
			list:AddLine(" 1 ->Apply<- (Directly apply settings to target)")
		else
			list:AddLine(" 1   Apply   (Directly apply settings to target)")
		end
		if ( mode == 2 ) then
			list:AddLine(" 2 ->Rotate<- (Turn an object without moving it)")
		else
			list:AddLine(" 2   Rotate   (Turn an object without moving it)")
		end
		if ( mode == 3 ) then
			list:AddLine(" 3 ->Move<- (Snap objects together - Great for building!)")
		else
			list:AddLine(" 3   Move   (Snap objects together - Great for building!)")
		end
		if ( mode == 4 ) then
			list:AddLine(" 4 ->Weld<-")
		else
			list:AddLine(" 4   Weld")
		end
		if ( mode == 5 ) then
			list:AddLine(" 5 ->Axis<-")
		else
			list:AddLine(" 5   Axis")
		end
		if ( mode == 6 ) then
			list:AddLine(" 6 ->Ballsocket<-")
		else
			list:AddLine(" 6   Ballsocket")
		end
		if ( user >= 2 ) then
			if ( mode == 7 ) then
				list:AddLine(" 7 ->Adv Ballsocket<-")
			else
				list:AddLine(" 7   Adv Ballsocket")
			end
			if ( mode == 8 ) then
				list:AddLine(" 8 ->Slider<-")
			else
				list:AddLine(" 8   Slider")
			end
		end
		if ( user >= 3 ) then
			if ( mode == 9 ) then
				list:AddLine(" 9 ->Parent<- (Like a solid weld, but without object collision)")
			else
				list:AddLine(" 9   Parent   (Like a solid weld, but without object collision)")
			end
			if ( mode == 10 ) then
				list:AddLine("10 ->Repair<- (Re-welds - Experimental, probably useless)")
			else
				list:AddLine("10   Repair   (Re-welds - Experimental, probably useless)")
			end
		end

		list:SortByColumn(1)

		Panel:AddItem(list)



		local Moving = LocalPlayer():GetInfoNum( "precision_move", 1 ) == 1 && mode > 2 && mode <= 9
		local Rotating = (LocalPlayer():GetInfoNum( "precision_rotate", 1 ) == 1 || mode == 2) && mode <= 9
		if ( mode > 3 && mode <= 8 ) then
			Panel:AddControl( "Checkbox", { Label = "Move Target? ('Easy' constraint mode)", Command = "precision_move", Description = "Uncheck this to apply the constraint without altering positions." } )
		end
		if (  mode > 2 && mode <= 8 /*Moving || mode == 3*/ ) then
			Panel:AddControl( "Checkbox", { Label = "Rotate Target? (Rotation after moving)", Command = "precision_rotate", Description = "Uncheck this to remove the extra click for rotation. Handy for speed building." } )
			//Panel:AddControl( "Label", { Text = "This is the distance from touching of the targeted props after moving:", Description	= "Use 0 mostly, % takes the second prop's width." }  )
			Panel:AddControl( "Slider",  { Label	= "Snap Distance",
					Type	= "Float",
					Min		= 0,
					Max		= 100,
					Command = "precision_offset",
					Description = "Distance offset between joined props.  Type in negative to inset when moving."}	 )
			Panel:AddControl( "Checkbox", { Label = "Snap distance as Percent (%) of target's depth", Command = "precision_offsetpercent", Description = "Unchecked = Exact units, Checked = takes % of width from second prop" } )
		end
		if ( mode > 1 && mode <= 8/*Moving || mode == 2 || mode == 3*//*Rotating && mode != 1*/ ) then
			Panel:AddControl( "Slider",  { Label	= "Rotation Snap (Degrees)",
					Type	= "Float",
					Min		= 0.02,
					Max		= 90,
					Command = "precision_rotation",
					Description = "Rotation rotates by this amount at a time. No more guesswork. Min: 0.02 degrees "}	 ):SetDecimals( 4 )
		end
		if ( mode != 9 ) then
			Panel:AddControl( "Checkbox", { Label = "Freeze Target", Command = "precision_freeze", Description = "Freeze props when this tool is used" } )

			if ( mode > 2 ) then
				Panel:AddControl( "Checkbox", { Label = "No Collide Targets", Command = "precision_nocollide", Description = "Nocollide pairs of props when this tool is used. Note: No current way to remove this constraint when used alone."  } )
			end
		end


		if ( user >= 2 || mode == 1 ) then
			if ( (mode > 2 && mode < 9) || mode == 1 ) then
				Panel:AddControl( "Checkbox", { Label = "Auto-align to world (nearest 45 degrees)", Command = "precision_autorotate", Description = "Rotates to the nearest world axis (similar to holding sprint and use with physgun)"  } )
			end

			if ( mode == 1 ) then
				Panel:AddControl( "Checkbox", { Label = "Disable target shadow", Command = "precision_ShadowDisable", Description = "Disables shadows cast from the prop"  } )
			end
		end

		if ( user >= 3 ) then
			if ( mode == 1 ) then //apply
				Panel:AddControl( "Checkbox", { Label = "Only Collide with Player", Command = "precision_nocollideall", Description = "Nocollides the first prop to everything and the world (except players collide with it). Warning: don't let it fall away through the world."  } )
				Panel:AddControl( "Checkbox", { Label = "Disable Physics on object", Command = "precision_physdisable", Description = "Disables physics on the first prop (gravity, being shot etc won't effect it)"  } )
				Panel:AddControl( "Checkbox", { Label = "Adv: Allow Physgun on PhysDisable objects", Command = "precision_allowphysgun", Description = "Disabled to stop accidents, use if you want to be able to manually move props after phyics disabling them (may break clipboxes)."  } )
			end
			if ( mode == 9 ) then //parent
				Panel:AddControl( "Checkbox", { Label = "Adv: Allow Physgun on Parented objectss", Command = "precision_allowphysgun", Description = "Disabled to stop accidents, use this if you want to play with the parenting hierarchy etc."  } )
			end
		end
		if ( mode >= 4 && mode <= 9 ) then
			Panel:AddControl( "Checkbox", { Label = "Constraint Removal Mode", Command = "precision_removal", Description = "When enabled, attempts to undo constraints of the current mode on targeted props (Much like the reload function of other tools).  Use 'move' mode to remove nocollideall constraint." } )
		end
		if ( user >= 2 ) then
			if ( mode != 2 ) then //todo: entire contrap rotate support
				Panel:AddControl( "Checkbox", { Label = "Entire Contraption! (Everything connected to target)", Command = "precision_entirecontrap", Description = "For mass constraining or removal or nudging or applying of things. Yay generic."  } )
			end
		end

		if ( user >= 2 ) then
			if ( (mode >= 4 && mode <= 7) || mode == 10 ) then //breakable constraint
				Panel:AddControl( "Slider",  { Label	= "Force Breakpoint",
						Type	= "Float",
						Min		= 0.0,
						Max		= 50000,
						Command = "precision_forcelimit",
						Description = "Applies to most constraint modes" }	 )
			end


			if ( mode == 5 || mode == 6 || mode == 7 ) then //axis or ballsocket
				Panel:AddControl( "Slider",  { Label	= "Torque Breakpoint",
						Type	= "Float",
						Min		= 0.0,
						Max		= 50000,
						Command = "precision_torquelimit",
						Description = "Breakpoint of turning/rotational force"}	 )
			end
		end

		if ( mode == 5 ) then //axis
			Panel:AddControl( "Slider",  { Label	= "Axis Friction",
					Type	= "Float",
					Min		= 0.0,
					Max		= 100,
					Command = "precision_friction",
					Description = "Turning resistance, this is best at 0 in most cases to conserve energy"}	 )
		end

		if ( mode ==7 ) then //adv ballsocket
			Panel:AddControl( "Slider",  { Label	= "X Rotation Minimum",
					Type	= "Float",
					Min		= -180,
					Max		= 180,
					Command = "precision_XRotMin",
					Description = "Rotation minimum of advanced ballsocket in X axis"}	 )

			Panel:AddControl( "Slider",  { Label	= "X Rotation Maximum",
					Type	= "Float",
					Min		= -180,
					Max		= 180,
					Command = "precision_XRotMax",
					Description = "Rotation maximum of advanced ballsocket in X axis"}	 )

			Panel:AddControl( "Slider",  { Label	= "Y Rotation Minimum",
					Type	= "Float",
					Min		= -180,
					Max		= 180,
					Command = "precision_YRotMin",
					Description = "Rotation minimum of advanced ballsocket in Y axis"}	 )

			Panel:AddControl( "Slider",  { Label	= "Y Rotation Maximum",
					Type	= "Float",
					Min		= -180,
					Max		= 180,
					Command = "precision_YRotMax",
					Description = "Rotation maximum of advanced ballsocket in Y axis"}	 )

			Panel:AddControl( "Slider",  { Label	= "Z Rotation Minimum",
					Type	= "Float",
					Min		= -180,
					Max		= 180,
					Command = "precision_ZRotMin",
					Description = "Rotation minimum of advanced ballsocket in Z axis"}	 )

			Panel:AddControl( "Slider",  { Label	= "Z Rotation Maximum",
					Type	= "Float",
					Min		= -180,
					Max		= 180,
					Command = "precision_ZRotMax",
					Description = "Rotation maximum of advanced ballsocket in Z axis"}	 )

			Panel:AddControl( "Slider",  { Label	= "X Rotation Friction",
					Type	= "Float",
					Min		= 0,
					Max		= 100,
					Command = "precision_XRotFric",
					Description = "Rotation friction of advanced ballsocket in X axis"}	 )

			Panel:AddControl( "Slider",  { Label	= "Y Rotation Friction",
					Type	= "Float",
					Min		= 0,
					Max		= 100,
					Command = "precision_YRotFric",
					Description = "Rotation friction of advanced ballsocket in Y axis"}	 )

			Panel:AddControl( "Slider",  { Label	= "Z Rotation Friction",
					Type	= "Float",
					Min		= 0,
					Max		= 100,
					Command = "precision_ZRotFric",
					Description = "Rotation friction of advanced ballsocket in Z axis"}	 )

			Panel:AddControl( "Checkbox", { Label = "Free Movement", Command = "precision_FreeMov", Description = "Only lock relative rotation, not position?"  } )
		end

		if ( mode == 8 ) then //slider
			Panel:AddControl( "Slider",  { Label	= "Slider Width",
					Type	= "Float",
					Min		= 0.0,
					Max		= 10,
					Command = "precision_width",
					Description = "Width of the slider black line (0 = invisible)"}	 )

			Panel:AddControl( "Checkbox", { Label = "Turn Off Minor Slider Stabilisation", Command = "precision_disablesliderfix", Description = "Fix being seperate X/Y/Z advanced ballsocket locks between the props.  This stops most spaz caused by rotation, but not spaz caused by displacement." } )
			Panel:AddControl( "Label", { Text = "Stabilisation is seperate X/Y/Z adv. ballsockets; it makes it far less prone to rotation triggered spaz, but the difference is only noticible sometimes as it's still just as prone to spaz caused by drifting.", Description	= "Due to lack of working descriptions at time of coding" }  )
		end

		if ( mode == 9 ) then //parent
			Panel:AddControl( "Label", { Text = "Parenting Notes:", Description	= "Due to lack of working descriptions at time of coding" }  )
			Panel:AddControl( "Label", { Text = "Parenting objects is most similar to a very strong weld, but it stops most interaction on the first object when you attach it to the second.  Players can walk on it, but it will fall through players.  It will not collide with objects or the world.  It will also not cause any extra physics lag/spaz.  Try it out on a test object, and decide if it's useful to you!", Description	= "Due to lack of working descriptions at time of coding" }  )

			Panel:AddControl( "Label", { Text = "Parented objects are most useful for: Adding detail to moving objects without creating extra physics lag.  Things like houses that you want to move (though you can only safely walk on parented objects when they are still.)", Description	= "Due to lack of working descriptions at time of coding" }  )

			Panel:AddControl( "Label", { Text = "Possible issues:  Remove constraints first to avoid spaz. Duplicating or such may cause the collision model to become seperated.  Best to test it if in doubt.", Description	= "Why must labels cause menu flicker? D:" }  )
		end
		if ( showgenmenu == 1 ) then
			Panel:AddControl( "Button", { Label = "\\/ General Tool Options \\/", Command = "precision_generalmenu", Description = "Collapse menu"  } )




		local params = {Label = "User Level",Description = "Shows options appropriate to user experience level", MenuButton = "0", Height = 67, Options = {}}
		if ( user == 1 ) then
			params.Options[" 1 ->Normal<-"] = { precision_setuser = "1" }
		else
			params.Options[" 1   Normal"] = { precision_setuser = "1" }
		end
		if ( user == 2 ) then
			params.Options[" 2 ->Advanced<-"] = { precision_setuser = "2" }
		else
			params.Options[" 2   Advanced"] = { precision_setuser = "2" }
		end
		if ( user == 3 ) then
			params.Options[" 3 ->Experimental<-"] = { precision_setuser = "3" }
		else
			params.Options[" 3   Experimental"] = { precision_setuser = "3" }
		end

		Panel:AddControl( "ListBox", params )

			//Panel:AddControl( "Label", { Text = "General Tool Options:", Description	= "Note: These don't save with presets." }  )
			Panel:AddControl( "Checkbox", { Label = "Enable tool feedback messages?", Command = "precision_enablefeedback", Description = "Toggle for feedback messages incase they get annoying"  } )
			Panel:AddControl( "Checkbox", { Label = "On = Feedback in Chat, Off = Centr Scrn", Command = "precision_chatfeedback", Description = "Chat too cluttered? Can have messages centre screen instead"  } )
			//Panel:AddControl( "Checkbox", { Label = "Hide Menu Tips?", Command = "precision_hidehints", Description = "Streamline the menu once you're happy with using the tool."  } )
			Panel:AddControl( "Checkbox", { Label = "Add Push/Pull to Undo List", Command = "precision_nudgeundo", Description = "For if you're in danger of nudging somthing to where you can't reach it"  } )
			Panel:AddControl( "Checkbox", { Label = "Add Movement to Undo List", Command = "precision_moveundo", Description = "So you don't have to secondary fire with nocollide to undo mistakes"  } )
			Panel:AddControl( "Checkbox", { Label = "Add Rotation to Undo List", Command = "precision_rotateundo", Description = "So you can find the exact rotation value easier"  } )
			Panel:AddControl( "Button", { Label = "Restore Current Mode Default", Command = "precision_defaultrestore", Description = "Collapse menu"  } )
		else
			Panel:AddControl( "Button", { Label = "-- General Tool Options --", Command = "precision_generalmenu", Description = "Expand menu"  } )
		end
	end
	local function precision_defaults()
		local mode = LocalPlayer():GetInfoNum( "precision_mode", 3 )
		if mode  == 1 then
			RunConsoleCommand("precision_freeze", "1")
			RunConsoleCommand("precision_autorotate", "1")
			RunConsoleCommand("precision_ShadowDisable", "0")
			RunConsoleCommand("precision_nocollideall", "0")
			RunConsoleCommand("precision_physdisable", "0")
			RunConsoleCommand("precision_allowphysgun", "0")
			RunConsoleCommand("precision_entirecontrap", "0")
		elseif mode == 2 then
			RunConsoleCommand("precision_rotation", "15")
			RunConsoleCommand("precision_freeze", "1")
			RunConsoleCommand("precision_entirecontrap", "0")
		elseif mode == 3 then
			RunConsoleCommand("precision_rotate", "1")
			RunConsoleCommand("precision_offset", "0")
			RunConsoleCommand("precision_offsetpercent", "1")
			RunConsoleCommand("precision_rotation", "15")
			RunConsoleCommand("precision_freeze", "1")
			RunConsoleCommand("precision_nocollide", "1")
			RunConsoleCommand("precision_autorotate", "1")
			RunConsoleCommand("precision_entirecontrap", "0")
		elseif mode == 4 then
			RunConsoleCommand("precision_move", "1")
			RunConsoleCommand("precision_rotate", "1")
			RunConsoleCommand("precision_offset", "0")
			RunConsoleCommand("precision_offsetpercent", "1")
			RunConsoleCommand("precision_rotation", "15")
			RunConsoleCommand("precision_freeze", "1")
			RunConsoleCommand("precision_nocollide", "1")
			RunConsoleCommand("precision_autorotate", "0")
			RunConsoleCommand("precision_removal", "0")
			RunConsoleCommand("precision_entirecontrap", "0")
			RunConsoleCommand("precision_forcelimit", "0")
		elseif mode == 5 then
			RunConsoleCommand("precision_move", "1")
			RunConsoleCommand("precision_rotate", "1")
			RunConsoleCommand("precision_offset", "0")
			RunConsoleCommand("precision_offsetpercent", "1")
			RunConsoleCommand("precision_rotation", "15")
			RunConsoleCommand("precision_freeze", "1")
			RunConsoleCommand("precision_nocollide", "1")
			RunConsoleCommand("precision_autorotate", "0")
			RunConsoleCommand("precision_removal", "0")
			RunConsoleCommand("precision_entirecontrap", "0")
			RunConsoleCommand("precision_forcelimit", "0")
			RunConsoleCommand("precision_torquelimit", "0")
			RunConsoleCommand("precision_friction", "0")
		elseif mode == 6 then
			RunConsoleCommand("precision_move", "1")
			RunConsoleCommand("precision_rotate", "1")
			RunConsoleCommand("precision_offset", "0")
			RunConsoleCommand("precision_offsetpercent", "1")
			RunConsoleCommand("precision_rotation", "15")
			RunConsoleCommand("precision_freeze", "1")
			RunConsoleCommand("precision_nocollide", "1")
			RunConsoleCommand("precision_autorotate", "0")
			RunConsoleCommand("precision_removal", "0")
			RunConsoleCommand("precision_entirecontrap", "0")
			RunConsoleCommand("precision_forcelimit", "0")
			RunConsoleCommand("precision_torquelimit", "0")
		elseif mode == 7 then
			RunConsoleCommand("precision_move", "0")
			RunConsoleCommand("precision_rotate", "1")
			RunConsoleCommand("precision_offset", "0")
			RunConsoleCommand("precision_offsetpercent", "1")
			RunConsoleCommand("precision_rotation", "15")
			RunConsoleCommand("precision_freeze", "1")
			RunConsoleCommand("precision_nocollide", "1")
			RunConsoleCommand("precision_autorotate", "0")
			RunConsoleCommand("precision_removal", "0")
			RunConsoleCommand("precision_entirecontrap", "0")
			RunConsoleCommand("precision_forcelimit", "0")
			RunConsoleCommand("precision_torquelimit", "0")
			RunConsoleCommand("precision_XRotMin", "0")
			RunConsoleCommand("precision_XRotMax", "0")
			RunConsoleCommand("precision_YRotMin", "0")
			RunConsoleCommand("precision_YRotMax", "0")
			RunConsoleCommand("precision_ZRotMin", "0")
			RunConsoleCommand("precision_ZRotMax", "0")
			RunConsoleCommand("precision_XRotFric", "0")
			RunConsoleCommand("precision_YRotFric", "0")
			RunConsoleCommand("precision_ZRotFric", "0")
			RunConsoleCommand("precision_FreeMov", "1")
		elseif mode == 8 then
			RunConsoleCommand("precision_move", "1")
			RunConsoleCommand("precision_rotate", "1")
			RunConsoleCommand("precision_offset", "0")
			RunConsoleCommand("precision_offsetpercent", "1")
			RunConsoleCommand("precision_rotation", "15")
			RunConsoleCommand("precision_freeze", "1")
			RunConsoleCommand("precision_nocollide", "0")
			RunConsoleCommand("precision_autorotate", "0")
			RunConsoleCommand("precision_removal", "0")
			RunConsoleCommand("precision_entirecontrap", "0")
			RunConsoleCommand("precision_width", "1")
			RunConsoleCommand("precision_disablesliderfix", "0")
		elseif mode == 9 then
			RunConsoleCommand("precision_removal", "0")
			RunConsoleCommand("precision_allowphysgun", "0")
			RunConsoleCommand("precision_entirecontrap", "0")
		end
		precision_updatecpanel()
	end
	concommand.Add( "precision_defaultrestore", precision_defaults )

	local function precision_genmenu()
		if ( showgenmenu == 1 ) then
			showgenmenu = 0
		else
			showgenmenu = 1
		end
		precision_updatecpanel()
	end
	concommand.Add( "precision_generalmenu", precision_genmenu )

	function precision_setmode( player, tool, args )
		if LocalPlayer():GetInfoNum( "precision_mode", 3 ) != args[1] then
			RunConsoleCommand("precision_mode", args[1])
			timer.Simple(0.05, function() precision_updatecpanel() end ) 
		end
	end
	concommand.Add( "precision_setmode", precision_setmode )


	function precision_setuser( player, tool, args )
		if LocalPlayer():GetInfoNum( "precision_user", 3 ) != args[1] then
			RunConsoleCommand("precision_user", args[1])
			timer.Simple(0.05, function() precision_updatecpanel() end ) 
		end
	end
	concommand.Add( "precision_setuser", precision_setuser )


	function precision_updatecpanel()
		local Panel = controlpanel.Get( "precision" )
		if (!Panel) then return end
		//custom panel building ( wtf does Panel:AddDefaultControls() get it's defaults from? )
		AddDefControls( Panel )
	end
	concommand.Add( "precision_updatecpanel", precision_updatecpanel )

	function TOOL.BuildCPanel( Panel )
		AddDefControls( Panel )
	end


	function TOOL:FreezeMovement()
		local iNum = self:GetStage()
		if ( iNum > 1 ) then
			return true
		elseif ( iNum > 0 && self:GetClientNumber("mode") == 2 ) then
			return true
		end
		return false
	end
end

function TOOL:Holster()
	self:ClearObjects()
end