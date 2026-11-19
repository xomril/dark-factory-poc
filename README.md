dark-factory-poc/
├── .github/
│   └── workflows/
│       ├── 01-architect-spec.yml    # תחנה 1: הופך Issue ל-Spec טכני
│       ├── 02-builder-code.yml      # תחנה 2: כותב קוד ופותח PR
│       └── 03-qa-gatekeeper.yml     # תחנה 3: בודק את ה-PR ומחזיר לתיקון או מאשר
├── .factory/                        # "חדר הבקרה" של הסוכנים
│   ├── prompts/
│   │   ├── architect.md
│   │   ├── builder.md
│   │   └── qa-reviewer.md
│   ├── FACTORY_RULES.md             # חוקי בטיחות (Guardrails, מגבלת ריצות)
│   └── metrics.json                 # לוג אוטומטי של עלויות, זמנים והצלחות
├── src/                             # קוד המוצר שהמפעל מייצר
├── tests/                           # טסטים שהמפעל כותב ומריץ
└── README.md                        # חלון הראווה למי שמגיע מהפוסטים שלך
