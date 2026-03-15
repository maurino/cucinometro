from django.urls import path
from . import views

app_name = 'meals'

urlpatterns = [
    path('', views.home, name='home'),
    path('create-meal/', views.create_meal, name='create_meal'),
    path('decide-dishwasher/', views.decide_dishwasher, name='decide_dishwasher'),
    path('create-member/', views.create_member, name='create_member'),
    path('statistics/', views.statistics, name='statistics'),
]