# Garmin Watch App - Subagent Development & Marketing Plan

Based on the agents repository at https://github.com/wshobson/agents

---

## Development Phase Subagents

### 1. UI/UX Designer
**Purpose**: Interface design, wireframes, design systems
**Why Critical**: Garmin watches have small screens (varies by device). Need intuitive, minimal UI that works with limited screen real estate and touch/button navigation.

**Tasks**:
- Design watch face layouts
- Create app flow and navigation
- Design icons and glyphs optimized for small displays
- Ensure readability in various lighting conditions

---

### 2. Mobile Developer
**Purpose**: React Native and Flutter application development
**Application**: While Garmin uses Monkey C (not React Native), mobile dev patterns apply.

**Tasks**:
- Implement app logic and state management
- Handle data persistence on device
- Implement background services
- Manage app lifecycle events

---

### 3. Performance Engineer
**Purpose**: Application profiling and optimization
**Why Critical**: Watches have limited CPU, memory, and battery. Performance is crucial.

**Tasks**:
- Optimize memory usage (strict limits per device)
- Reduce CPU cycles for battery efficiency
- Profile and optimize rendering
- Minimize wake time and background processing

---

### 4. API Documenter
**Purpose**: Technical documentation
**Tasks**:
- Document code architecture
- Create API reference for any companion app
- Write developer notes
- Document data structures and protocols

---

### 5. Tutorial Engineer
**Purpose**: Creating user guides
**Tasks**:
- Write user manual for watch app
- Create quick start guide
- Develop troubleshooting documentation
- Build video tutorials or screenshots

---

## Marketing & Launch Phase Subagents

### 6. Content Marketer
**Purpose**: Blog posts, social media, email campaigns
**Tasks**:
- Create launch announcement content
- Manage social media presence
- Develop email marketing campaigns
- Create promotional blog posts

---

### 7. SEO Content Writer
**Purpose**: SEO-optimized content creation
**Tasks**:
- Optimize Garmin Connect IQ Store listing
- Write SEO-friendly blog posts
- Create landing page content
- Optimize meta descriptions and keywords

---

### 8. Business Analyst
**Purpose**: Metrics analysis, reporting, KPI tracking
**Tasks**:
- Track download metrics
- Analyze user engagement data
- Monitor app ratings and reviews
- Create performance reports
- Identify improvement opportunities

---

### 9. Sales Automator
**Purpose**: Monetization strategies
**Tasks**:
- Define pricing strategy (free vs. paid vs. freemium)
- Set up payment processing (if applicable)
- Create upsell/cross-sell strategies
- Develop partner/affiliate programs

---

## Development Workflow

### Phase 1: Design & Planning (Week 1-2)
**Active Subagents**: UI/UX Designer, Business Analyst
- Define app concept and features
- Design interface mockups
- Define target devices
- Set success metrics

### Phase 2: Development (Week 3-8)
**Active Subagents**: Mobile Developer, Performance Engineer
- Implement core functionality
- Build UI components
- Integrate with Garmin APIs
- Optimize performance

### Phase 3: Documentation (Week 7-9)
**Active Subagents**: API Documenter, Tutorial Engineer
- Write technical documentation
- Create user guides
- Develop troubleshooting docs

### Phase 4: Testing & Optimization (Week 9-10)
**Active Subagents**: Performance Engineer, Mobile Developer
- Test on multiple devices
- Optimize performance
- Fix bugs
- User acceptance testing

### Phase 5: Pre-Launch Marketing (Week 10-11)
**Active Subagents**: Content Marketer, SEO Content Writer
- Build landing page
- Create promotional content
- Set up social media
- Prepare launch materials

### Phase 6: Launch (Week 12)
**Active Subagents**: Content Marketer, Sales Automator
- Submit to Connect IQ Store
- Execute launch campaign
- Monitor initial response

### Phase 7: Post-Launch (Ongoing)
**Active Subagents**: Business Analyst, Content Marketer, Tutorial Engineer
- Monitor metrics
- Respond to user feedback
- Create update content
- Plan future features

---

## Subagent Implementation Notes

To implement these subagents from the repository:

1. Clone the agents repository:
   ```bash
   git clone https://github.com/wshobson/agents.git
   ```

2. Each subagent is a specialized prompt/configuration that can be integrated into your development workflow

3. Use subagents as needed throughout the project lifecycle

4. Adapt subagent prompts to Garmin-specific context (Monkey C, Connect IQ Store, etc.)

---

## Priority Order

**Immediate (Before Development)**:
1. UI/UX Designer - Design the app first

**During Development**:
2. Mobile Developer - Core development
3. Performance Engineer - Continuous optimization

**Before Launch**:
4. Tutorial Engineer - User documentation
5. API Documenter - Technical docs
6. Content Marketer - Marketing materials
7. SEO Content Writer - Store optimization

**Post-Launch**:
8. Business Analyst - Ongoing metrics
9. Sales Automator - Monetization optimization
