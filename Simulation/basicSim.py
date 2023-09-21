import pygame
import math
from collections import deque

# this package uses pygame
# you can install it by executing this command:
# python -m pip install pygame

class Route:
    def __init__(self, points, color):
        self.points = points
        self.color = color

class Point:
    def __init__(self, x, y, max_speed):
        self.x = x
        self.y = y
        self.max_speed = max_speed
        self.agents = deque()

    def is_used(self):
        return len(self.agents) > 0

    def register(self,agent):
        self.agents.append(agent)



class Agent:
    count = 0
    def __init__(self, x, y, max_speed,color,goal,route):
        self.x = x
        self.y = y
        self.max_speed = max_speed
        self.color = color
        self.goal = goal
        self.route = route

        self.id = self.count
        self.count += 1

    def move_towards(self,point,time):
        direction_x = point.x - self.x
        direction_y = point.y - self.y

        normalization_factor = math.sqrt(direction_x * direction_x + direction_y * direction_y)

        x_normalized = direction_x / normalization_factor
        y_normalized = direction_y / normalization_factor

        self.x += (x_normalized * min(point.max_speed,self.max_speed) * time)
        self.y += (y_normalized * min(point.max_speed,self.max_speed) * time)

    def is_on_point(self, point):
        margin_of_error = 5
        result = abs(self.x - point.x) < margin_of_error and abs(self.y - point.y) < margin_of_error 
        return result

#general rules in the simulation:
#only one agent can between to points at the same time
#agents wait at points
#agents have a max speed
#tracks have a max speed

#create list of points our agent should try to reach 
intersection = Point(80,130,150)

points_one = []
points_one.append(  Point(20,20,60))
points_one.append(  Point(180,90,60))
points_one.append(  intersection)
points_one.append(  Point(130,200,90))
points_one.append(  Point(20,250,100))
route_one = Route(points_one,(20,80,20))

points_two = []
points_two.append(  Point(120,180,60))
points_two.append(  intersection)
points_two.append(  Point(230,170,90))
points_two.append(  Point(180,300,100))
points_two.append(  Point(200,200,1000))
route_two = Route(points_two,(20,20,80))

points_three = points_two.copy()
points_three.reverse()
route_three = Route(points_three,(20,20,80))

routes = []
routes.append(route_one)
routes.append(route_two)
routes.append(route_three)

#create agent (and set his start position to the first point)
agents = []

#function to create agents and put them correctly on the grid
def create_agent( route, start,color, speed):
    agent = Agent(route.points[start].x, route.points[start].y,speed, color, start+1,route)
    agents.append(agent)
    route.points[start+1].register(agent)

#create agents
#green ones
create_agent(routes[0], 0,(0,200,0),120)       
create_agent(routes[0], 0,(0,200,0),80)
create_agent(routes[0], 0,(0,200,0),130)
create_agent(routes[0], 0,(0,200,0),150)

#blue ones
create_agent(routes[1], 2,(0,0,200),110)       
create_agent(routes[1], 2,(0,0,200),70) 
create_agent(routes[1], 2,(0,0,200),130) 
create_agent(routes[1], 2,(0,0,200),180) 

#red ones
create_agent(routes[2], 2,(200,0,0),130) 
create_agent(routes[2], 2,(200,0,0),130) 

#setup gameengine and window
pygame.init()
WIDTH = 800
HEIGHT = 600
screen = pygame.display.set_mode([WIDTH, HEIGHT])

#variable for our game loop, tracking goals and delta time
getTicksLastFrame = 0
running = True

#Simulation loop
while running:   
    t = pygame.time.get_ticks()
    #speed: 2 = 2x ; 0.5 = 0.5x
    speed = 2
    # deltaTime in seconds.
    deltaTime = (t - getTicksLastFrame) / 1000.0 * speed
    getTicksLastFrame = t

    #loop to check if user wants to quit the application
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
    
    #set background to white
    screen.fill((255, 255, 255))

    # draw routes
    for route in routes:
        for p in route.points:
            #draw points
            pygame.draw.circle(screen, route.color, (p.x, p.y), 5)
        
        #draw lines between points
        prev_point = route.points[0]
        for l in range(0,len(route.points)+1):
            i = l%len(route.points)
            pygame.draw.line(screen, route.color, (prev_point.x,prev_point.y), (route.points[i].x,route.points[i].y))
            prev_point = route.points[i]

    #loop to update each agent
    for agent in agents:
        p = agent.route.points[agent.goal]
        
        # agent asks if he can use the route
        if( not (agent in p.agents)):
            p.register(agent)

        # move agent if route is not occupied and he is the first one in queue
        if(p.agents[0] == agent):
            agent.move_towards(p,deltaTime)
        
        # if agent reached its goal, and empty queue
        if(agent.is_on_point(p)):
            p.agents.popleft()
            agent.goal = (agent.goal + 1) % len(agent.route.points)

        #draw point on screen
        pygame.draw.circle(screen, agent.color, (agent.x, agent.y), 10)
        

    # update screen
    pygame.display.flip()

