extends Resource
class_name ShopResource

## Ресурс продавца.
## Все "комментарии" — это DialogueText ресурсы: у каждого свой голос, скорость, питч.
## При входе в каждый режим выбирается случайный.

## Реплики при открытии магазина (MAIN)
@export var greetings     : Array[DialogueText] = []

## Товары на продажу
@export var stock         : Array[Item]          = []

## Реплики в режиме "Купить"
@export var buy_comments  : Array[DialogueText]  = []

## Реплики в режиме "Продать"
@export var sell_comments : Array[DialogueText]  = []

## Темы разговора (ShopTalkTopic ресурсы)
@export var talk_topics   : Array[Resource]      = []

## Реплики в режиме "Поговорить"
@export var talk_comments : Array[DialogueText]  = []
