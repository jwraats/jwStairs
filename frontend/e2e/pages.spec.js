import { test, expect } from '@playwright/test'

test.describe('JW Stairs Pages', () => {
  test('Animations page loads and displays controls', async ({ page }) => {
    await page.goto('/')
    
    // Verify the header and navigation
    await expect(page.locator('header')).toBeVisible()
    await expect(page.getByText('JW Stairs')).toBeVisible()
    await expect(page.locator('nav a[href="/"]')).toBeVisible()
    await expect(page.locator('nav a[href="/scenes"]')).toBeVisible()
    
    // Verify animation controls panel
    await expect(page.getByText('Animation Controls')).toBeVisible()
    await expect(page.getByText('Brightness')).toBeVisible()
    await expect(page.getByText('Primary Color')).toBeVisible()
    await expect(page.getByText('Color Order')).toBeVisible()
    
    // Take screenshot
    await page.screenshot({ path: 'e2e/screenshots/animations-page.png', fullPage: true })
  })

  test('Scenes page loads and displays content', async ({ page }) => {
    await page.goto('/scenes')
    
    // Verify the page header is visible
    await expect(page.getByRole('heading', { name: 'Scenes' })).toBeVisible()
    
    // Take screenshot
    await page.screenshot({ path: 'e2e/screenshots/scenes-page.png', fullPage: true })
  })

  test('Scene Detail page loads with back button', async ({ page }) => {
    await page.goto('/scenes/1')
    
    // Verify scene detail page has the back button
    await expect(page.getByText('← Back')).toBeVisible()
    
    // Take screenshot
    await page.screenshot({ path: 'e2e/screenshots/scene-detail-page.png', fullPage: true })
  })

  test('Navigation between pages works', async ({ page }) => {
    // Start at animations page
    await page.goto('/')
    await expect(page.getByText('Animation Controls')).toBeVisible()
    
    // Navigate to scenes page via nav link
    await page.click('nav a[href="/scenes"]')
    await expect(page.getByRole('heading', { name: 'Scenes' })).toBeVisible()
    
    // Take screenshot after navigation
    await page.screenshot({ path: 'e2e/screenshots/navigation-to-scenes.png', fullPage: true })
    
    // Navigate back to animations page via nav link
    await page.click('nav a[href="/"]')
    await expect(page.getByText('Animation Controls')).toBeVisible()
    
    // Take screenshot after navigation back
    await page.screenshot({ path: 'e2e/screenshots/navigation-to-animations.png', fullPage: true })
  })
})
