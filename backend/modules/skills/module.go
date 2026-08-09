package skills

type SkillsModule struct {
	store *Store
}

func New(rootDir string) *SkillsModule {
	return &SkillsModule{store: NewStore(rootDir)}
}

func (m *SkillsModule) Name() string { return "skills" }

func (m *SkillsModule) Initialize() error {
	return m.store.Load()
}

func (m *SkillsModule) Shutdown() error { return nil }
