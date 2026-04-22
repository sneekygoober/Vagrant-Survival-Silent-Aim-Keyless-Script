if not game:IsLoaded() then game.Loaded:Wait(); end;

local cloneref = cloneref or function(i: Instance) return i; end;
local clonefunction = clonefunction or function(f: (...any) -> (...any)) return f; end;
local newcclosure = newcclosure or clonefunction;
local executor = (identifyexecutor and select(2, pcall(identifyexecutor))) and identifyexecutor() or "Your executor";
local SG = loadstring(game:HttpGet("https://raw.githubusercontent.com/sneekygoober/sneeky-s-notifications/refs/heads/main/main.luau"))();

if not (hookfunction and require) then
    local err = executor .. " is missing " .. (not hookfunction and "hookfunction " or "") .. (not require and "require" or "");
    SG["error"](err);
    return error(err);
end;

local RS: ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"));
local Players: Players = cloneref(game:GetService("Players"));
local UIS: UserInputService = cloneref(game:GetService("UserInputService"));

local plr = Players.LocalPlayer;
local cam = workspace.CurrentCamera;

local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled and not UIS.MouseEnabled;

local s, rm = pcall(require, RS.Modules.Shared.RayUtils.RayMouse);
if not s then
    return warn(executor .. " returned an error while trying to require RS.Modules.Shared.RayUtils.RayRaycast:\n" .. rm);
end;

local s2, srvs = pcall(require, RS.FrameworkFiles.Srvs);
if not s2 then
    return warn(executor .. " returned an error while trying to require RS.FrameworkFiles.Srvs:\n" .. srvs);
end;

local Chars, Enemies, mif, ic = workspace:FindFirstChild("Spawned")
    and workspace.Spawned:FindFirstChild("Characters"), workspace:FindFirstChild("Spawned")
    and workspace.Spawned:FindFirstChild("Enemies"), workspace:FindFirstChild("Spawned")
    and workspace.Spawned:FindFirstChild("MouseIgnoreFolder"), RS:FindFirstChild("Modules")
    and RS.Modules:FindFirstChild("Shared")
    and RS.Modules.Shared:FindFirstChild("GameConfiguration")
    and RS.Modules.Shared.GameConfiguration:FindFirstChild("ItemConfigs");

if not (Chars and mif and ic) then
    local err = "Script needs updating";
    SG["error"](err);
    return warn(err);
end;

for _, v: ModuleScript in next, ic:GetChildren() do local old; old = clonefunction(hookfunction(require(v), function(...) return rawset(old(...), "ProjectileSpread", 0); end)); end;

local rp = RaycastParams.new();
rp.FilterType = Enum.RaycastFilterType.Exclude;
rp.IgnoreWater = true;

local isVisible = function(part: BasePart, origin: Vector3): (boolean, Instance?)
    local char = plr.Character;
    if not (char and part) then return false, nil; end;

    rp.FilterDescendantsInstances = {char, mif};

    local origin = origin or cam.CFrame.Position;

    local dir = part.Position - origin;
    local result: RaycastResult = workspace:Raycast(origin, dir, rp);
    if not result then return true, nil; end;

    if result.Instance:IsDescendantOf(part.Parent) then
        return true, result.Instance;
    end;

    return false, result.Instance;
end;

local getTarget = function(origin: Vector3)
    local cPart, cDistance = nil, getgenv().fov or 300;

    local tmp = table.create(#Chars:GetChildren() + #Enemies:GetChildren());

    local i = 0;
    for _, v in next, Chars:GetChildren() do i += 1; tmp[i] = v; end;
    for _, v in next, Enemies:GetChildren() do i += 1; tmp[i] = v; end;

    for _, char: Model in next, tmp do
        if char == plr.Character or (char:FindFirstChild("HumanoidRootPart") and char.HumanoidRootPart:FindFirstChild("ForceField1", true)) or (char:FindFirstChild("Humanoid") and char.Humanoid.Health <= 0) then continue; end;

        local tPart: BasePart = char:FindFirstChild("Head") or char.PrimaryPart or char:FindFirstChild("HumanoidRootPart");
        if not tPart then continue; end;

        local pos, onScreen = cam:WorldToViewportPoint(tPart.Position);
        if not onScreen then continue; end;

        local v, nTPart = isVisible(tPart, origin);
        if not v then
            v, nTPart = isVisible(char.PrimaryPart or char:FindFirstChild("HumanoidRootPart"), origin);
            if not v then continue; end;
        end;

        if nTPart then tPart = nTPart; end;

        local distance = (Vector2.new(pos.X, pos.Y) - (isMobile and Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2) or UIS:GetMouseLocation())).Magnitude;
        if distance < cDistance then
            cPart = tPart;
            cDistance = distance;
        end;
    end;

    return cPart;
end;

loadstring(game:HttpGet("https://raw.githubusercontent.com/sneekygoober/sneeky-s-fov-lib/refs/heads/main/main.luau"))()(getgenv().fov or 300, getTarget, true);

rawset(srvs, "UserInputService", setmetatable({}, {
    __index = function(_, k)
        if k == "TouchEnabled" and debug.getinfo(2).source == "=ReplicatedStorage.Modules.Client.Behaviours.BehaviourGunClient" then
            return false;
        end;

        local v = UIS[k];

        if typeof(v) == "function" then
            return function(_, ...)
                return v(UIS, ...);
            end;
        end;

        return v;
    end;
}));

local old; old = clonefunction(hookfunction(rawget(rm, "GetMousePosition"), newcclosure(function()
    local c = getTarget();
    if c then
        return c.Position;
    end;
    return old();
end)));

SG["success"]("Silent aim successfully executed!\nIf you have any issues press F9 or type /console in chat and then send me a screenshot of the console.");
