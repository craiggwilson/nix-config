/**
 * Tests for agent and team selection prompt templates
 */

import { describe, it, expect } from "bun:test"

import { teamCompositionTemplate, singleAgentSelectionTemplate } from "./selection.js"

describe("teamCompositionTemplate", () => {
  it("has correct name and description", () => {
    expect(teamCompositionTemplate.name).toBe("team-composition")
    expect(teamCompositionTemplate.description).toContain("team composition")
  })

  it("includes issue context", () => {
    const prompt = teamCompositionTemplate.render({
      issueContext: "Implement user authentication feature",
      agents: [{ name: "coder" }],
    })

    expect(prompt).toContain("Implement user authentication feature")
    expect(prompt).toContain("ISSUE:")
  })

  it("lists available agents", () => {
    const prompt = teamCompositionTemplate.render({
      issueContext: "Test issue",
      agents: [
        { name: "coder", description: "Writes code" },
        { name: "reviewer", description: "Reviews code" },
      ],
    })

    expect(prompt).toContain("AVAILABLE AGENTS:")
    expect(prompt).toContain("coder: Writes code")
    expect(prompt).toContain("reviewer: Reviews code")
  })

  it("shows (no description) for agents without description", () => {
    const prompt = teamCompositionTemplate.render({
      issueContext: "Test issue",
      agents: [{ name: "mystery-agent" }],
    })

    expect(prompt).toContain("mystery-agent: (no description)")
  })

  it("includes team selection rules", () => {
    const prompt = teamCompositionTemplate.render({
      issueContext: "Test issue",
      agents: [{ name: "coder" }],
    })

    expect(prompt).toContain("3-4 agents")
    expect(prompt).toContain("PRIMARY")
    expect(prompt).toContain("REVIEW")
    expect(prompt).toContain("complementary skills")
  })

  it("includes JSON format instructions", () => {
    const prompt = teamCompositionTemplate.render({
      issueContext: "Test issue",
      agents: [{ name: "coder" }],
    })

    expect(prompt).toContain('"agents"')
    expect(prompt).toContain("JSON only")
  })

  it("truncates long issue context", () => {
    const longContext = "x".repeat(10000)
    const prompt = teamCompositionTemplate.render({
      issueContext: longContext,
      agents: [{ name: "coder" }],
    })

    expect(prompt.length).toBeLessThan(longContext.length)
  })
})

describe("singleAgentSelectionTemplate", () => {
  it("has correct name and description", () => {
    expect(singleAgentSelectionTemplate.name).toBe("single-agent-selection")
    expect(singleAgentSelectionTemplate.description).toContain("single agent")
  })

  it("includes task description", () => {
    const prompt = singleAgentSelectionTemplate.render({
      taskDescription: "Fix the login bug",
      agents: [{ name: "debugger" }],
    })

    expect(prompt).toContain("Fix the login bug")
    expect(prompt).toContain("TASK DESCRIPTION:")
  })

  it("lists available agents", () => {
    const prompt = singleAgentSelectionTemplate.render({
      taskDescription: "Test task",
      agents: [
        { name: "coder", description: "Writes code" },
        { name: "tester", description: "Writes tests" },
      ],
    })

    expect(prompt).toContain("AVAILABLE AGENTS:")
    expect(prompt).toContain("coder: Writes code")
    expect(prompt).toContain("tester: Writes tests")
  })

  it("shows (no description) for agents without description", () => {
    const prompt = singleAgentSelectionTemplate.render({
      taskDescription: "Test task",
      agents: [{ name: "unknown-agent" }],
    })

    expect(prompt).toContain("unknown-agent: (no description)")
  })

  it("includes JSON format instructions with reason", () => {
    const prompt = singleAgentSelectionTemplate.render({
      taskDescription: "Test task",
      agents: [{ name: "coder" }],
    })

    expect(prompt).toContain('"agent"')
    expect(prompt).toContain('"reason"')
    expect(prompt).toContain("valid JSON")
  })

  it("truncates long task description", () => {
    const longDescription = "x".repeat(2000)
    const prompt = singleAgentSelectionTemplate.render({
      taskDescription: longDescription,
      agents: [{ name: "coder" }],
    })

    expect(prompt.length).toBeLessThan(longDescription.length + 500)
  })
})
